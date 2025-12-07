pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@rails/actioncable", to: "actioncable.esm.js", preload: true

pin "channels", to: "channels/index.js", preload: true
pin_all_from "app/javascript/channels", under: "channels"
