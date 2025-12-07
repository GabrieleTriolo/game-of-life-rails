import consumer from "channels/consumer"

function patchGrid(grid) {
  const table = document.getElementById("grid");
  if (!table) return;

  // per ogni cella inviata dal server
  for (let r = 0; r < grid.length; r++) {
    const row = grid[r];
    for (let c = 0; c < row.length; c++) {
      const wantAlive = row[c] === "*";
      // trova la td con data-r/data-c (DOM stabile)
      const cell = table.querySelector(`td[data-r="${r}"][data-c="${c}"]`);
      if (!cell) continue;
      const isAlive = cell.classList.contains("alive");
      if (wantAlive !== isAlive) {
        cell.classList.toggle("alive", wantAlive);
        cell.classList.toggle("dead", !wantAlive);
        // opzionale: micro effetto nascita/morte
        // cell.style.transform = "scale(1.06)";
        // setTimeout(() => cell.style.transform = "", 120);
      }
    }
  }
}

window.subscribeSimulation = function(simulationId) {
  return consumer.subscriptions.create(
    { channel: "SimulationChannel", simulation_id: simulationId },
    {
      connected()  { console.log("AC connected") },
      rejected()   { console.warn("AC rejected") },
      disconnected(){ console.warn("AC disconnected") },

      received(data) {
        // sempre aggiorna testo generazione
        const gen = document.getElementById("gen");
        if (data.generation !== undefined && gen) gen.textContent = data.generation;

        if (data.grid) {
          // patch animata (consigliato)
          patchGrid(data.grid);
        } else if (data.html) {
          // fallback: replace completo
          const gameArea = document.getElementById("game_area");
          if (gameArea) gameArea.innerHTML = data.html;
        }

        if (data.finished) {
          const btn = document.getElementById("start-btn");
          if (btn) btn.disabled = false;
        }
      }
    }
  )
}
