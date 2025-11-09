package main

import (
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"time"
)

var LogUtil *LogManager

type Log struct {
	Log  string
	Time time.Time
}

// LogManager 管理日志的内存和文件写入
type LogManager struct {
	buffer []Log      // 内存中日志的环形缓冲区
	start  int        // 缓冲区的起始索引
	size   int        // 当前缓冲区中的日志条数
	cap    int        // 缓冲区容量
	logDir string     // 日志文件目录
	mu     sync.Mutex // 并发安全
}

// NewLogManager 创建一个新的日志管理器
func NewLogManager(capacity int, logDir string) *LogManager {
	err := os.MkdirAll(logDir, os.ModePerm)
	if err != nil {
		panic(err)
	}
	return &LogManager{
		buffer: make([]Log, capacity),
		start:  0,
		size:   0,
		cap:    capacity,
		logDir: logDir,
	}
}
func (lm *LogManager) Info(args ...interface{}) {
	lm.AddLog("info", fmt.Sprint(args...))
}
func (lm *LogManager) Warn(args ...interface{}) {
	lm.AddLog("warn", fmt.Sprint(args...))
}
func (lm *LogManager) Error(args ...interface{}) {
	lm.AddLog("error", fmt.Sprint(args...))
}

// AddLog 添加一条日志到内存和文件
func (lm *LogManager) AddLog(level string, log string) {
	lm.mu.Lock()
	defer lm.mu.Unlock()
	now := time.Now()
	nowStr := now.Format("2006-01-02 15:04:05.000")
	log = fmt.Sprintf("[%s] %s %s", level, nowStr, log)
	bufferLog := Log{
		Log:  log,
		Time: now,
	}
	// 1. 写入内存缓冲区
	if lm.size < lm.cap {
		// 缓冲区未满，直接添加
		lm.buffer[(lm.start+lm.size)%lm.cap] = bufferLog
		lm.size++
	} else {
		// 缓冲区已满，覆盖最旧日志
		lm.buffer[lm.start] = bufferLog
		lm.start = (lm.start + 1) % lm.cap
	}
	println(log)
	// 2. 写入文件
	lm.writeToFile(log)
}

// writeToFile 将日志写入当天的日志文件
func (lm *LogManager) writeToFile(log string) {
	// 获取当前日期作为文件名
	fileName := time.Now().Format("2006-01-02") + ".txt"
	filePath := lm.logDir + "/" + fileName

	// 打开文件，使用追加模式；如果不存在则创建
	// 提取文件路径中的目录部分
	dir := filepath.Dir(filePath)

	// 确保目录存在，如果不存在就创建
	err := os.MkdirAll(dir, 0755)
	if err != nil {
		fmt.Printf("无法创建文件夹: %v\n", err)
		return
	}
	file, err := os.OpenFile(filePath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		fmt.Printf("无法打开日志文件: %v\n", err)
		return
	}
	defer file.Close()

	// 写入日志内容，带换行符
	_, err = file.WriteString(log + "\n")
	if err != nil {
		fmt.Printf("写入日志文件失败: %v\n", err)
	}
}

// GetAllMemoryLogs 获取内存中按顺序排列的所有日志
func (lm *LogManager) GetAllMemoryLogs() []Log {
	lm.mu.Lock()
	defer lm.mu.Unlock()

	logs := make([]Log, lm.size)
	for i := 0; i < lm.size; i++ {
		logs[i] = lm.buffer[(lm.start+i)%lm.cap]
	}
	return logs
}

// ResizeBuffer 动态调整缓冲区大小
func (lm *LogManager) ResizeBuffer(newCap int) {
	lm.mu.Lock()
	defer lm.mu.Unlock()

	if newCap <= 0 {
		fmt.Println("缓冲区容量必须大于 0")
		return
	}

	// 创建一个新的缓冲区
	newBuffer := make([]Log, newCap)
	newSize := lm.size

	// 如果是缩容，只保留最新的日志
	if newCap < lm.size {
		newSize = newCap
	}

	// 按顺序将现有日志复制到新缓冲区
	for i := 0; i < newSize; i++ {
		newBuffer[i] = lm.buffer[(lm.start+lm.size-newSize+i)%lm.cap]
	}

	// 更新缓冲区状态
	lm.buffer = newBuffer
	lm.start = 0
	lm.size = newSize
	lm.cap = newCap
}
func OnDeferRecover() {
	if err := recover(); err != nil {
		msg := fmt.Sprintf("%v", err)
		LogUtil.Error(msg)
	}
}
