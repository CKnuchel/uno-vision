package hub

import (
	"encoding/json"
	"log"
)

type Hub interface {
	Broadcast(partyID uint, event string, payload interface{})
	Register(client *Client)
	Unregister(client *Client)
	Run()
}

type hub struct {
	parties    map[uint]map[*Client]bool
	broadcast  chan Message
	register   chan *Client
	unregister chan *Client
}

type Message struct {
	PartyID uint        `json:"party_id"`
	Event   string      `json:"event"`
	Payload interface{} `json:"payload"`
}

func NewHub() Hub {
	return &hub{
		parties:    make(map[uint]map[*Client]bool),
		broadcast:  make(chan Message),
		register:   make(chan *Client),
		unregister: make(chan *Client),
	}
}

// Run starts the hub event loop - must be called as a goroutine
func (h *hub) Run() {
	for {
		select {
		case client := <-h.register:
			// Create party map if it doesn't exist yet
			if _, ok := h.parties[client.PartyID]; !ok {
				h.parties[client.PartyID] = make(map[*Client]bool)
			}
			h.parties[client.PartyID][client] = true

		case client := <-h.unregister:
			// Remove client from party
			if clients, ok := h.parties[client.PartyID]; ok {
				if _, ok := clients[client]; ok {
					delete(clients, client)
					close(client.Send)
					// Clean up empty party
					if len(clients) == 0 {
						delete(h.parties, client.PartyID)
					}
				}
			}

		case message := <-h.broadcast:
			// Send message to all clients in the party
			if clients, ok := h.parties[message.PartyID]; ok {
				data, err := json.Marshal(message)
				if err != nil {
					log.Printf("error marshalling message: %v", err)
					continue
				}
				for client := range clients {
					select {
					case client.Send <- data:
					default:
						// Client send buffer full - disconnect
						close(client.Send)
						delete(clients, client)
					}
				}
			}
		}
	}
}

// Register sends a client to the register channel
func (h *hub) Register(client *Client) {
	h.register <- client
}

// Unregister sends a client to the unregister channel
func (h *hub) Unregister(client *Client) {
	h.unregister <- client
}

// Broadcast sends an event with payload to all clients in a party
func (h *hub) Broadcast(partyID uint, event string, payload interface{}) {
	h.broadcast <- Message{
		PartyID: partyID,
		Event:   event,
		Payload: payload,
	}
}
