// utils/socketManager.js
let io = null;

export const setIo = (ioInstance) => {
  io = ioInstance;
};

export const getIo = () => {
  if (!io) {
    throw new Error('Socket.io instance not initialized');
  }
  return io;
};

export const getOnlineUserIds = () => {
  if (!io) return [];
  
  const onlineUserIds = [];
  const rooms = io.sockets.adapter.rooms;
  
  // Extract online user IDs
  for (const [room, sockets] of rooms.entries()) {
    if (room.startsWith('user:')) {
      const userId = room.replace('user:', '');
      onlineUserIds.push(userId);
    }
  }
  
  return onlineUserIds;
};