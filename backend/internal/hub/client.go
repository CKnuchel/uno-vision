package hub

import (
	"log"
	"time"

	"github.com/gorilla/websocket"
)

const (
	// Time allowed to write a message to the peer
	writeWait = 10 * time.Second

	// Time allowed to read the next pong message from the peer
	pongWait = 60 * time.Second

	// Send pings to peer with this period - must be less than pongWait
	pingPeriod = (pongWait * 9) / 10

	// Maximum message size allowed from peer
	maxMessageSize = 512
)

// Client represents a single WebSocket connection associated with a party
type Client struct {
	hub      Hub
	Conn     *websocket.Conn
	Send     chan []byte
	PartyID  uint
	PlayerID uint
}

// NewClient creates a new Client and registers it with the hub
func NewClient(hub Hub, conn *websocket.Conn, partyID, playerID uint) *Client {
	return &Client{
		hub:      hub,
		Conn:     conn,
		Send:     make(chan []byte, 256),
		PartyID:  partyID,
		PlayerID: playerID,
	}
}

// readPump listens for incoming messages from the WebSocket connection.
// Its primary purpose is to detect disconnections and respond to pings.
// Clients do not send game messages - only the server broadcasts.
func (c *Client) ReadPump() {
	defer func() {
		// Unregister client from hub and close connection on exit
		c.hub.Unregister(c)
		c.Conn.Close()
	}()

	c.Conn.SetReadLimit(maxMessageSize)
	c.Conn.SetReadDeadline(time.Now().Add(pongWait))

	// Reset read deadline on every pong received
	c.Conn.SetPongHandler(func(string) error {
		c.Conn.SetReadDeadline(time.Now().Add(pongWait))
		return nil
	})

	// Keep reading to detect disconnects - we don't process incoming messages
	for {
		_, _, err := c.Conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("websocket error: %v", err)
			}
			break
		}
	}
}

// writePump sends messages from the hub to the WebSocket connection.
// It also sends periodic pings to keep the connection alive.
func (c *Client) WritePump() {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		c.Conn.Close()
	}()

	for {
		select {
		case message, ok := <-c.Send:
			c.Conn.SetWriteDeadline(time.Now().Add(writeWait))

			if !ok {
				// Hub closed the channel - send close message
				c.Conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			// Write the message as a text frame
			w, err := c.Conn.NextWriter(websocket.TextMessage)
			if err != nil {
				return
			}
			w.Write(message)

			// Flush any queued messages into the same frame
			n := len(c.Send)
			for i := 0; i < n; i++ {
				w.Write([]byte{'\n'})
				w.Write(<-c.Send)
			}

			if err := w.Close(); err != nil {
				return
			}

		case <-ticker.C:
			// Send ping to keep connection alive
			c.Conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.Conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}
