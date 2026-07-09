package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/gorilla/websocket"
)

// clientConnection 包装 WebSocket 连接，集中处理同一连接的串行写入约束。
type clientConnection struct {
	conn *websocket.Conn
	// gorilla/websocket 只允许单个 writer 并发写入，写锁用于避免通知转发和 ping ack 抢写同一连接。
	writeLock sync.Mutex
}

// 定义全局变量
var (
	// WebSocket升级器
	upgrader = websocket.Upgrader{
		ReadBufferSize:  1024,
		WriteBufferSize: 1024,
		CheckOrigin: func(r *http.Request) bool {
			return true // 允许所有跨域请求，生产环境应根据需要修改
		},
	}

	// 并发安全的连接映射
	connections = struct {
		sync.RWMutex
		KeyMap map[string][]*clientConnection
		//设备id和连接的映射
		DevMap map[string]*clientConnection
	}{KeyMap: make(map[string][]*clientConnection), DevMap: make(map[string]*clientConnection)}
	logs *LogManager
)

const (
	online       = "online"
	offline      = "offline"
	syncFile     = "syncFile"
	ping         = "ping"
	checkVersion = "checkVersion"
)

const version = "1.1.0"

const (
	// 写超时用于避免网络黑洞时单次消息发送长期阻塞。
	writeWait = 10 * time.Second
	// 读超时用于清理长期无任何客户端消息的半开连接，需大于客户端 ping 间隔。
	pongWait = 90 * time.Second
)

type MsgData struct {
	Operation   string `json:"operation"`
	TargetDevId string `json:"targetDevId"`
	Data        string `json:"data"`
}

func main() {
	port := flag.Int("port", 8083, "Port to listen on")
	flag.Parse()
	logs = NewLogManager(1000, "./data/logs")
	http.HandleFunc("/connect/", handleWebSocket)
	http.HandleFunc("/"+checkVersion, handleCheckVersion)
	logs.Info("WebSocket server started on :" + strconv.Itoa(*port))
	logs.Error(http.ListenAndServe(":"+strconv.Itoa(*port), nil))
}

// handleCheckVersion 返回通知服务版本，供客户端判断公共服务是否可用。
func handleCheckVersion(w http.ResponseWriter, r *http.Request) {
	_, err := w.Write([]byte(version))
	if err != nil {
		host := r.Host
		logs.Error("Error writing version from " + host)
		return
	}
}

// handleWebSocket 建立设备通知通道，并通过应用层 ping/ack 识别半开连接。
func handleWebSocket(w http.ResponseWriter, r *http.Request) {
	// 从URL路径中提取参数
	content := strings.TrimPrefix(r.URL.Path, "/connect/")
	var key string
	var devId string
	if content == "" {
		msg := "Missing key parameter"
		http.Error(w, msg, http.StatusBadRequest)
		logs.Error(msg)
		return
	}
	parts := strings.Split(content, ":")
	if len(parts) != 2 {
		msg := "Invalid connection parameter: " + content
		http.Error(w, msg, http.StatusBadRequest)
		logs.Error(msg)
		return
	}
	key = parts[0]
	devId = parts[1]
	// 升级HTTP连接到WebSocket
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		msg := fmt.Sprintf("Failed to upgrade to WebSocket: %s", err)
		logs.Error(msg)
		return
	}
	defer conn.Close()
	client := &clientConnection{conn: conn}

	// 将连接添加到映射中
	addConnection(key, devId, client)

	// 当连接关闭时从映射中移除
	defer removeConnection(key, devId, client)
	logs.Info("WebSocket connection established. key = " + key + " devId = " + devId)
	// 保持连接活跃
	for {
		// 读取消息
		// 客户端会定期发送应用层 ping，超时未收到任何消息时认为连接已经半开。
		_ = conn.SetReadDeadline(time.Now().Add(pongWait))
		msgType, data, err := conn.ReadMessage()
		if err != nil {
			logs.Error("Error reading from websocket: key = ", key, ",err = ", err)
			break
		}
		if msgType != websocket.TextMessage {
			logs.Error("Unexpected message type from websocket: key = ", key, ",msgType = ", msgType)
			break
		}
		var msg MsgData
		err = json.Unmarshal(data, &msg)
		if err != nil {
			logs.Error("Error unmarshalling from websocket: key = ", key, ",err = ", err)
			break
		}
		targetDevId := msg.TargetDevId
		operation := msg.Operation

		if operation == ping {
			if err := writeMessage(client, MsgData{Operation: ping, TargetDevId: devId, Data: ""}); err != nil {
				logs.Error("Failed to send ping ack. key = ", key, ", devId = ", devId, ",err = ", err)
				break
			}
			continue
		}

		connections.Lock()
		ws, ok := connections.DevMap[msg.TargetDevId]
		connections.Unlock()
		if ok {
			if err := writeMessage(ws, MsgData{Operation: operation, TargetDevId: devId, Data: msg.Data}); err != nil {
				logs.Error("Failed to send change message. from devId: ", devId, ", targetDevId: ", targetDevId, ",err = ", err)
			}
		} else {
			logs.Warn("Device not found in connection list: ", targetDevId)
		}
	}
}

// addConnection 添加当前设备连接；同设备旧连接会被替换，避免旧会话继续占用转发表。
func addConnection(key string, devId string, conn *clientConnection) {

	connections.Lock()
	if oldConn, ok := connections.DevMap[devId]; ok {
		removeConnectionLocked(key, devId, oldConn)
		_ = oldConn.conn.Close()
	}

	// 复制一份需要通知的列表，避免持锁执行网络写入导致其他连接阻塞。
	notifyList := make([]*clientConnection, len(connections.KeyMap[key]))
	copy(notifyList, connections.KeyMap[key])

	connections.KeyMap[key] = append(connections.KeyMap[key], conn)
	connections.DevMap[devId] = conn

	connections.Unlock()

	logs.Info(fmt.Sprintf("Added connection for key: %s, total connections for this key: %d", key, len(connections.KeyMap[key])))

	notifyConnections(notifyList, online, devId)
}

// removeConnection 从映射中移除指定连接；只有当前活跃连接才会删除 DevMap，避免旧会话误删新会话。
func removeConnection(key string, devId string, conn *clientConnection) {

	connections.Lock()

	removed := removeConnectionLocked(key, devId, conn)

	// 复制一份需要通知的列表，避免持锁执行网络写入导致其他连接阻塞。
	notifyList := make([]*clientConnection, len(connections.KeyMap[key]))
	copy(notifyList, connections.KeyMap[key])

	connections.Unlock()

	if !removed {
		logs.Warn("Connection already removed or replaced. key = ", key, ", devId = ", devId)
		return
	}

	//设备下线通知
	notifyConnections(notifyList, offline, devId)
}

// removeConnectionLocked 在持有连接表写锁时移除连接，调用方负责解锁和发送下线通知。
func removeConnectionLocked(key string, devId string, conn *clientConnection) bool {
	removed := false
	if conns, ok := connections.KeyMap[key]; ok {
		for i, c := range conns {
			if c == conn {
				// 从切片中删除连接。
				connections.KeyMap[key] = append(conns[:i], conns[i+1:]...)
				logs.Info(fmt.Sprintf("Removed connection for key: %s, remaining connections: %d", key, len(connections.KeyMap[key])))

				// 如果该 key 没有连接了，从 map 中删除 key。
				if len(connections.KeyMap[key]) == 0 {
					delete(connections.KeyMap, key)
					logs.Info(fmt.Sprintf("No more connections for key: %s, removed from map", key))
				}
				removed = true
				break
			}
		}
	}
	if activeConn, ok := connections.DevMap[devId]; ok && activeConn == conn {
		delete(connections.DevMap, devId)
	}
	return removed
}

// notifyConnections 向同一存储空间内的其他设备广播上下线事件。
func notifyConnections(conns []*clientConnection, operation string, devId string) {
	for _, ws := range conns {
		if err := writeMessage(ws, MsgData{Operation: operation, Data: "", TargetDevId: devId}); err != nil {
			logs.Error("Failed to send offline message. devId = ", devId, ",err = ", err)
		}
	}
}

// writeMessage 统一设置写超时并串行化同一连接的写入，避免通知转发时出现并发写崩溃。
func writeMessage(client *clientConnection, msg MsgData) error {
	bytes, err := json.Marshal(msg)
	if err != nil {
		return err
	}
	client.writeLock.Lock()
	defer client.writeLock.Unlock()
	if err := client.conn.SetWriteDeadline(time.Now().Add(writeWait)); err != nil {
		return err
	}
	return client.conn.WriteMessage(websocket.TextMessage, bytes)
}
