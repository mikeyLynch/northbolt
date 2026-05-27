import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from "chart.js"
Chart.register(...registerables)

export default class extends Controller {
  static values = { labels: Array, data: Array }

  connect() {
    const ctx = this.element.getContext("2d")

    new Chart(ctx, {
      type: "line",
      data: {
        labels: this.labelsValue,
        datasets: [{
          data:                this.dataValue,
          borderColor:         "#111827",
          backgroundColor:     "rgba(17, 24, 39, 0.06)",
          borderWidth:         1.5,
          pointRadius:         3,
          pointBackgroundColor: "#111827",
          fill:                true,
          tension:             0.3
        }]
      },
      options: {
        responsive:          true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          x: {
            grid:   { display: false },
            ticks:  { color: "#9ca3af", font: { size: 12 } },
            border: { display: false }
          },
          y: {
            beginAtZero: true,
            ticks:  { color: "#9ca3af", font: { size: 12 }, precision: 0 },
            grid:   { color: "#f3f4f6" },
            border: { display: false }
          }
        }
      }
    })
  }
}
