'use strict';

const assert = require('node:assert/strict');

class ClassList {
  constructor() { this.values = new Set(); }
  add(value) { this.values.add(value); }
  remove(value) { this.values.delete(value); }
  contains(value) { return this.values.has(value); }
}

class FakeElement {
  constructor() {
    this.children = [];
    this.classList = new ClassList();
    this.style = {};
    this.disabled = false;
    this.textContent = '';
    this.innerHTML = '';
    this.listeners = {};
  }
  addEventListener(name, callback) { this.listeners[name] = callback; }
  appendChild(child) { this.children.push(child); }
  replaceChildren(...children) { this.children = children; }
  setAttribute() {}
  click() { this.listeners.click?.(); }
}

const elements = {};
global.document = {
  getElementById(id) { return elements[id] ??= new FakeElement(); },
  createElement() { return new FakeElement(); }
};
const timers = [];
global.window = { setTimeout(callback) { timers.push(callback); } };

require('../jogo.js');

assert.equal(elements.board.children.length, 100, 'o tabuleiro inicial deve ser renderizado');
elements.start.click();
assert.deepEqual(global.LumenGame.snapshot(), {
  active: 'Iria',
  phase: 'move',
  locked: false,
  livingAllies: 2,
  livingEnemies: 3,
  boardCells: 100
});
assert.equal(elements.intro.classList.contains('hidden'), true, 'o menu deve fechar ao iniciar');

// Iria begins at (1, 6); moving to the current cell is a valid "stay" action.
elements.board.children[6 * 10 + 1].click();
assert.equal(global.LumenGame.snapshot().phase, 'action');
assert.equal(elements.attack.disabled, false, 'ataque deve ser liberado depois do movimento');
elements.wait.click();
assert.equal(global.LumenGame.snapshot().locked, true, 'comandos devem bloquear durante a resolução');
assert.equal(timers.length, 1, 'fim de turno deve ser agendado somente uma vez');

// Restart invalidates callbacks from the old battle instead of corrupting the new one.
elements.restart.click();
assert.equal(global.LumenGame.snapshot().active, 'Iria');
timers.shift()();
assert.equal(global.LumenGame.snapshot().active, 'Iria', 'timer antigo deve ser ignorado após reiniciar');

console.log('PASS: iniciar, renderizar, mover, encerrar turno e reiniciar com segurança');
