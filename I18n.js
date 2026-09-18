.pragma library

var tables = {
  en: {
    newWindow: "New window",
    pin: "Pin to dock",
    unpin: "Unpin from dock",
    minimize: "Minimize",
    restore: "Restore",
    minimized: "Minimized",
    close: "Close",
    closeAll: "Close all windows",
    settings: "Dock settings",
    settingsTitle: "Dock",
    autohide: "Hide automatically",
    autohideHint: "Shows when the pointer touches the bottom edge",
    iconSize: "Icon size",
    monitor: "Monitor",
    allMonitors: "All",
    done: "Done"
  },
  pt: {
    newWindow: "Nova janela",
    pin: "Fixar no dock",
    unpin: "Desafixar do dock",
    minimize: "Minimizar",
    restore: "Restaurar",
    minimized: "Minimizada",
    close: "Fechar",
    closeAll: "Fechar todas as janelas",
    settings: "Configurar dock",
    settingsTitle: "Dock",
    autohide: "Ocultar automaticamente",
    autohideHint: "Aparece quando o ponteiro encosta na borda inferior",
    iconSize: "Tamanho dos ícones",
    monitor: "Monitor",
    allMonitors: "Todos",
    done: "Concluir"
  }
}

function tr(lang, key) {
  var table = tables[lang] || tables.en
  return table[key] || tables.en[key] || key
}
