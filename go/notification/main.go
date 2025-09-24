package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"sync"

	"github.com/gorilla/websocket"
)

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
		KeyMap map[string][]*websocket.Conn
		//设备id和连接的映射
		DevMap map[string]*websocket.Conn
	}{KeyMap: make(map[string][]*websocket.Conn), DevMap: make(map[string]*websocket.Conn)}
	logs *LogManager
)

const (
	online       = "online"
	offline      = "offline"
	syncFile     = "syncFile"
	checkVersion = "checkVersion"
)
const version = "1.0.0"

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

func handleCheckVersion(w http.ResponseWriter, r *http.Request) {
	_, err := w.Write([]byte(version))
	if err != nil {
		host := r.Host
		logs.Error("Error writing version from " + host)
		return
	}
}
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

	// 将连接添加到映射中
	addConnection(key, devId, conn)

	// 当连接关闭时从映射中移除
	defer removeConnection(key, devId, conn)
	logs.Info("WebSocket connection established. key = " + key + " devId = " + devId)
	// 保持连接活跃
	for {
		// 读取消息
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
		connections.Lock()
		ws, ok := connections.DevMap[msg.TargetDevId]
		connections.Unlock()
		if ok {
			sendData, err := json.Marshal(MsgData{Operation: operation, TargetDevId: devId, Data: msg.Data})
			if err != nil {
				logs.Error("Error marshalling from websocket: key = ", key, ",err = ", err)
				break
			}
			err = ws.WriteMessage(websocket.TextMessage, sendData)
			if err != nil {
				logs.Error("Failed to send change message. from devId: ", devId, ", targetDevId: ", targetDevId)
			}
		} else {
			logs.Warn("Device not found in connection list: ", targetDevId)
		}
	}
}

// 添加连接到映射
func addConnection(key string, devId string, conn *websocket.Conn) {

	connections.Lock()
	_, ok := connections.DevMap[devId]
	connections.Unlock()

	if ok {
		removeConnection(key, devId, conn)
	}

	connections.Lock()

	//复制一份需要通知的list
	notifyList := make([]*websocket.Conn, len(connections.KeyMap[key]))
	copy(notifyList, connections.KeyMap[key])

	connections.KeyMap[key] = append(connections.KeyMap[key], conn)
	connections.DevMap[devId] = conn

	connections.Unlock()

	logs.Info(fmt.Sprintf("Added connection for key: %s, total connections for this key: %d", key, len(connections.KeyMap[key])))

	notifyConnections(notifyList, online, devId)
}

// 从映射中移除连接
func removeConnection(key string, devId string, conn *websocket.Conn) {

	connections.Lock()

	if conns, ok := connections.KeyMap[key]; ok {
		for i, c := range conns {
			if c == conn {
				// 从切片中删除连接
				connections.KeyMap[key] = append(conns[:i], conns[i+1:]...)
				logs.Info(fmt.Sprintf("Removed connection for key: %s, remaining connections: %d", key, len(connections.KeyMap[key])))

				// 如果该key没有连接了，从map中删除key
				if len(connections.KeyMap[key]) == 0 {
					delete(connections.KeyMap, key)
					logs.Info(fmt.Sprintf("No more connections for key: %s, removed from map", key))
				}
				break
			}
		}
	}
	if _, ok := connections.DevMap[devId]; ok {
		delete(connections.DevMap, devId)
	}

	//复制一份需要通知的list
	notifyList := make([]*websocket.Conn, len(connections.KeyMap[key]))
	copy(notifyList, connections.KeyMap[key])

	connections.Unlock()

	logs.Info(fmt.Sprintf("Removed connection for key: %s, remaining connections: %d", key, len(connections.KeyMap[key])))

	//设备下线通知
	notifyConnections(notifyList, offline, devId)
}

func notifyConnections(conns []*websocket.Conn, operation string, devId string) {
	bytes, err := json.Marshal(MsgData{Operation: operation, Data: "", TargetDevId: devId})
	if err != nil {
		logs.Warn("Error marshalling offline: devId = ", devId, err)
	}
	for _, ws := range conns {
		err = ws.WriteMessage(websocket.TextMessage, bytes)
		if err != nil {
			logs.Error("Failed to send offline message. devId = ", devId, ",err = ", err)
		}
	}
}
