import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = ["startBtn", "stopBtn", "interval"]
  static values = {
    simulationId: Number,
    userId: Number
  }

  connect() {
    console.log("🎮 Simulation controller connected");
    
    // Crea consumer con user_id
    this.consumer = createConsumer(`/cable?user_id=${this.userIdValue}`);
    
    // Crea la sottoscrizione
    this.subscription = this.createSubscription();
    
    document.addEventListener('simulation:finished', this.onFinished.bind(this));
  }

  createSubscription() {
    return this.consumer.subscriptions.create(
      { channel: "SimulationChannel", simulation_id: this.simulationIdValue },
      {
        connected: () => {
          console.log("✅ WebSocket connected");
        },

        disconnected: () => {
          console.warn("⚠️ WebSocket disconnected");
        },

        received: (data) => {
          //console.log("📡 Data received:", data);
          
          const gen = document.getElementById("gen");
          if (data.generation !== undefined && gen) {
            gen.textContent = data.generation;
          }

          if (data.grid) {
            this.patchGrid(data.grid);
          } else if (data.html) {
            const gameArea = document.getElementById("game_area");
            if (gameArea) gameArea.innerHTML = data.html;
          }

          if (data.message) {
            this.showMessage(data.message, data.message_type);
          }

          if (data.finished) {
            const event = new CustomEvent('simulation:finished');
            document.dispatchEvent(event);
          }
        }
      }
    );
  }

  patchGrid(grid) {
    const table = document.getElementById("grid");
    if (!table) return;

    for (let r = 0; r < grid.length; r++) {
      for (let c = 0; c < grid[r].length; c++) {
        const wantAlive = grid[r][c] === "*";
        const cell = table.querySelector(`td[data-r="${r}"][data-c="${c}"]`);
        if (!cell) continue;
        
        const isAlive = cell.classList.contains("alive");
        if (wantAlive !== isAlive) {
          cell.classList.toggle("alive", wantAlive);
          cell.classList.toggle("dead", !wantAlive);
        }
      }
    }
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe();
    }
    if (this.consumer) {
      this.consumer.disconnect();
    }
    document.removeEventListener('simulation:finished', this.onFinished.bind(this));
  }

  async start(event) {
    event.preventDefault();
    
    const interval = this.intervalTarget.value || 500;
    const token = document.querySelector('meta[name="csrf-token"]').content;

    try {
      const response = await fetch(`/api/simulations/${this.simulationIdValue}/start`, {
        method: "POST",
        headers: {
          "X-CSRF-Token": token,
          "Content-Type": "application/x-www-form-urlencoded"
        },
        body: `interval_ms=${encodeURIComponent(interval)}`
      });

      if (response.ok) {
        this.startBtnTarget.disabled = true;
        this.stopBtnTarget.disabled = false;
        console.log("🚀 Simulation started");
      } else {
        alert("Error starting simulation");
      }
    } catch (error) {
      console.error("❌ Error:", error);
      alert("Network error");
    }
  }

  async stop(event) {
    event.preventDefault();
    
    const token = document.querySelector('meta[name="csrf-token"]').content;

    try {
      const response = await fetch(`/api/simulations/${this.simulationIdValue}/stop`, {
        method: "POST",
        headers: {
          "X-CSRF-Token": token
        }
      });

      if (response.ok) {
        this.startBtnTarget.disabled = false;
        this.stopBtnTarget.disabled = true;
        console.log("⏸️ Simulation stopped");
      }
    } catch (error) {
      console.error("❌ Error:", error);
    }
  }

  onFinished() {
    this.startBtnTarget.disabled = false;
    this.stopBtnTarget.disabled = true;
    console.log("✅ Simulation finished");
  }

  showMessage(text, type) {
    const messageDiv = document.createElement('div');
    messageDiv.className = `alert alert-${type === 'warning' ? 'danger' : 'info'}`;
    messageDiv.textContent = text;
    messageDiv.style.position = 'fixed';
    messageDiv.style.top = '20px';
    messageDiv.style.left = '50%';
    messageDiv.style.transform = 'translateX(-50%)';
    messageDiv.style.zIndex = '1000';
    
    document.body.appendChild(messageDiv);
  
    setTimeout(() => {
      messageDiv.remove();
    }, 3000);
  }
}