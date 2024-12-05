package network;

import sys.net.Socket;
import sys.net.Host;
import haxe.io.Bytes;
import haxe.Json;
import states.*;
import flixel.FlxG;

class Server {
    private static var socket:Socket;
    public static var isConnected:Bool = false;
    public static var roomCode:String = "";
    public static var isHost:Bool = false;
    public static var otherPlayerName:String = "";

    public static function connect(address:String, port:Int) {
        try {
            socket = new Socket();
            socket.connect(new Host(address), port);
            isConnected = true;
            trace("Connected to server!");
            
            sys.thread.Thread.create(() -> {
                while (isConnected) {
                    try {
                        var data = socket.input.readLine();
                        handleMessage(Json.parse(data));
                    } catch(e) {
                        trace("Error reading from socket: " + e);
                        isConnected = false;
                        break;
                    }
                }
            });
            
        } catch(e) {
            trace("Failed to connect: " + e);
        }
    }

    public static function sendMessage(type:String, data:Dynamic) {
        if (isConnected && socket != null) {
            try {
                var message = {
                    type: type,
                    data: data
                };
                var jsonString = Json.stringify(message) + "\n";
                socket.output.writeString(jsonString);
            } catch(e) {
                trace("Failed to send message: " + e);
                isConnected = false;
            }
        }
    }

    private static function handleMessage(data:Dynamic) {
        if (data == null) return;
        
        trace('Handling message type: ${data.type}');
        
        switch (data.type) {
            case "join_room":
                roomCode = data.room;
                isHost = data.isHost;
                otherPlayerName = data.otherPlayerName;
                trace('Joined room: $roomCode (Host: $isHost) with ${data.otherPlayerName}');
                
            case "player_joined":
                otherPlayerName = data.playerName;
                trace('Player joined: $otherPlayerName');
                
            case "player_left":
                otherPlayerName = "";
                trace('Other player left');
                
            case "create_room":
                roomCode = data.room;
                isHost = true;  
                trace('Created room: $roomCode (Host: true)');
                
            case "game_start":
                trace('Received game start with song data');
                if (Freeplay.instance != null) {
                    var songData = data.data.song;
                    trace('Starting song: ${songData.song}');
                    Freeplay.instance.startOnlineSong(songData);
                } else {
                    trace('Warning: Freeplay.instance is null!');
                }
                
            case "note_hit":
                if (PlayState.instance != null) {
                    PlayState.instance.handleOnlineNoteHit(data.data);
                }
                
            case "score_update":
                if (PlayState.instance != null) {
                    PlayState.instance.updateOpponentScore(
                        data.data.score, 
                        data.data.accuracy,
                        data.data.misses
                    );
                }
                
            case "force_start":
                trace('Received force start');
                if (!isHost && Freeplay.instance != null) {
                    trace('Guest forcing state change to Freeplay');
                    var freeplay = new Freeplay();
                    freeplay.isOnline = true;
                    freeplay.isHost = false;
                    FlxG.switchState(freeplay);
                }
                
            case "leave_room":
                roomCode = "";
                otherPlayerName = "";
                isHost = false;
                trace('Left room');
                
            default:
                trace("Unknown message type: " + data.type);
        }
    }
}