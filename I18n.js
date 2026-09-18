.pragma library

var tables = {
  en: {
    newWindow: "New window",
    pin: "Pin to dock",
    unpin: "Unpin from dock",
    minimize: "Minimize",
    restore: "Restore",
    minimized: "Minimized",
    applications: "Applications",
    trash: "Trash",
    open: "Open",
    emptyTrash: "Empty trash",
    confirmEmptyTrash: "Delete %1 items permanently",
    cancel: "Cancel",
    showTrash: "Show trash",
    showAppsButton: "Show applications button",
    pickerTitle: "Minimized windows",
    close: "Close",
    closeAll: "Close all windows",
    settings: "Dock settings",
    settingsTitle: "Dock",
    autohide: "Hide automatically",
    autohideHint: "Shows when the pointer touches the screen edge",
    iconSize: "Icon size",
    position: "Position",
    positionBottom: "Bottom",
    positionLeft: "Left",
    positionRight: "Right",
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
    applications: "Aplicativos",
    trash: "Lixeira",
    open: "Abrir",
    emptyTrash: "Esvaziar lixeira",
    confirmEmptyTrash: "Apagar %1 itens para sempre",
    cancel: "Cancelar",
    showTrash: "Mostrar lixeira",
    showAppsButton: "Mostrar botão de aplicativos",
    pickerTitle: "Janelas minimizadas",
    close: "Fechar",
    closeAll: "Fechar todas as janelas",
    settings: "Configurar dock",
    settingsTitle: "Dock",
    autohide: "Ocultar automaticamente",
    autohideHint: "Aparece quando o ponteiro encosta na borda da tela",
    iconSize: "Tamanho dos ícones",
    position: "Posição",
    positionBottom: "Embaixo",
    positionLeft: "Esquerda",
    positionRight: "Direita",
    monitor: "Monitor",
    allMonitors: "Todos",
    done: "Concluir"
  }
}

function tr(lang, key) {
  var table = tables[lang] || tables.en
  return table[key] || tables.en[key] || key
}
