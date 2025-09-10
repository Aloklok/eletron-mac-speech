// main.js
const { app, BrowserWindow } = require('electron');
const path = require('path');

function createWindow() {
  const win = new BrowserWindow({
    width: 800,
    height: 600,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false,
    }
  });
  win.loadFile('index.html');
}

app.whenReady().then(() => {
  createWindow();
  
  try {
    const addon = require('./native-addons/speech-recognizer/build/Release/speech_recognizer.node');
    console.log('✅ 原生模块加载成功!', addon);
    
    // 取消注释来调用它！
    addon.start({
      locale: 'ja-JP',
      onResult: (text) => {
        console.log('✅ 识别结果:', text);
      },
      onError: (error) => {
        console.error('❌ 识别错误:', error);
      }
    });

  } catch (error) {
    console.error('❌ 原生模块加载失败:', error);
  }
});