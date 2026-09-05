(() => {
  'use strict';

  const BOARD_SIZE = 10;
  const rocks = new Set(['4,2', '4,3', '4,4', '6,6', '7,6']);
  const moss = new Set(['2,4', '2,5', '3,5', '7,3']);
  const templates = {
    warden: { name: 'Kael', type: 'guerreiro', hp: 34, mp: 6, attack: 10, defense: 5, speed: 7, movement: 4, range: 1, skill: { name: 'Golpe Solar', power: 5, range: 1, cost: 3 } },
    ranger: { name: 'Iria', type: 'arqueiro', hp: 25, mp: 8, attack: 9, defense: 3, speed: 9, movement: 5, range: 3, skill: { name: 'Flecha Prismática', power: 4, range: 4, cost: 3 } },
    raider: { name: 'Vark', type: 'guerreiro', hp: 22, mp: 4, attack: 8, defense: 3, speed: 6, movement: 4, range: 1, skill: { name: 'Investida', power: 3, range: 1, cost: 2 } },
    seer: { name: 'Oráculo', type: 'mago', hp: 18, mp: 10, attack: 10, defense: 2, speed: 5, movement: 3, range: 3, skill: { name: 'Pulso Umbral', power: 5, range: 3, cost: 4 } }
  };

  let units = [];
  let turnQueue = [];
  let active = null;
  let phase = 'idle';
  let action = '';
  let reachable = new Map();
  let locked = true;
  let session = 0;

  const element = (id) => document.getElementById(id);
  const positionKey = (x, y) => `${x},${y}`;
  const distance = (a, b) => Math.abs(a.x - b.x) + Math.abs(a.y - b.y);
  const living = (team) => units.filter((unit) => unit.team === team && unit.hp > 0);
  const occupantAt = (x, y) => units.find((unit) => unit.hp > 0 && unit.x === x && unit.y === y);

  function createUnit(templateName, team, x, y, customName) {
    const source = templates[templateName];
    return {
      ...source,
      skill: { ...source.skill },
      name: customName || source.name,
      maxHp: source.hp,
      maxMp: source.mp,
      team,
      x,
      y
    };
  }

  function schedule(callback, delay) {
    const scheduledSession = session;
    window.setTimeout(() => {
      if (scheduledSession === session) callback();
    }, delay);
  }

  function resetGame() {
    session += 1;
    units = [
      createUnit('warden', 'ally', 1, 4),
      createUnit('ranger', 'ally', 1, 6),
      createUnit('raider', 'enemy', 8, 2),
      createUnit('raider', 'enemy', 8, 5, 'Rusk'),
      createUnit('seer', 'enemy', 8, 8)
    ];
    turnQueue = [];
    active = null;
    phase = 'idle';
    action = '';
    reachable.clear();
    locked = false;
    element('result').classList.add('hidden');
    nextTurn();
  }

  function reachableCells(start, budget, mover) {
    const costs = new Map([[positionKey(start.x, start.y), 0]]);
    const frontier = [{ x: start.x, y: start.y }];
    while (frontier.length > 0) {
      const current = frontier.shift();
      for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
        const x = current.x + dx;
        const y = current.y + dy;
        const key = positionKey(x, y);
        const occupant = occupantAt(x, y);
        if (x < 0 || y < 0 || x >= BOARD_SIZE || y >= BOARD_SIZE || rocks.has(key) || (occupant && occupant !== mover)) continue;
        const newCost = costs.get(positionKey(current.x, current.y)) + (moss.has(key) ? 2 : 1);
        if (newCost <= budget && (!costs.has(key) || newCost < costs.get(key))) {
          costs.set(key, newCost);
          frontier.push({ x, y });
        }
      }
    }
    return costs;
  }

  function nextTurn() {
    if (living('enemy').length === 0) return finishBattle(true);
    if (living('ally').length === 0) return finishBattle(false);

    // A unit defeated earlier in the round must never receive its queued turn.
    turnQueue = turnQueue.filter((unit) => unit.hp > 0);
    if (turnQueue.length === 0) {
      turnQueue = units.filter((unit) => unit.hp > 0).sort((a, b) => b.speed - a.speed);
    }

    active = turnQueue.shift();
    phase = 'move';
    action = '';
    reachable = reachableCells(active, active.movement, active);
    render(active.team === 'ally' ? `Turno de ${active.name}. Escolha uma casa azul.` : `${active.name} está agindo...`);

    if (active.team === 'enemy') {
      locked = true;
      schedule(runEnemyTurn, 450);
    }
  }

  function runEnemyTurn() {
    const targets = living('ally').sort((a, b) => (distance(active, a) * 10 + a.hp) - (distance(active, b) * 10 + b.hp));
    const target = targets[0];
    if (!target) return nextTurn();

    const destinations = [...reachable.keys()]
      .map((key) => {
        const [x, y] = key.split(',').map(Number);
        return { x, y };
      })
      .sort((a, b) => distance(a, target) - distance(b, target));

    if (destinations.length > 0) {
      active.x = destinations[0].x;
      active.y = destinations[0].y;
    }

    let message = `${active.name} avançou.`;
    if (distance(active, target) <= active.range) {
      const damage = Math.max(1, active.attack - target.defense);
      target.hp = Math.max(0, target.hp - damage);
      message = `${active.name} causou ${damage} de dano em ${target.name}.`;
    }
    locked = false;
    render(message);
    schedule(nextTurn, 550);
  }

  function handleTileClick(x, y) {
    if (locked || !active || active.team !== 'ally') return;
    const target = occupantAt(x, y);

    if (phase === 'move' && reachable.has(positionKey(x, y))) {
      active.x = x;
      active.y = y;
      phase = 'action';
      reachable.clear();
      render(`Escolha uma ação para ${active.name}.`);
      return;
    }

    if (phase !== 'target' || !target || target.team === active.team) return;
    const usingSkill = action === 'skill';
    const range = usingSkill ? active.skill.range : active.range;
    if (distance(active, target) > range) return render('Esse alvo está fora do alcance.');
    if (usingSkill && active.mp < active.skill.cost) return render('MP insuficiente. Escolha outra ação.');

    if (usingSkill) active.mp -= active.skill.cost;
    const damage = Math.max(1, active.attack + (usingSkill ? active.skill.power : 0) - target.defense);
    target.hp = Math.max(0, target.hp - damage);
    locked = true;
    render(`${active.name} causou ${damage} de dano em ${target.name}!`);
    schedule(() => {
      locked = false;
      nextTurn();
    }, 500);
  }

  function chooseAction(kind) {
    if (locked || !active || active.team !== 'ally' || phase !== 'action') return;
    action = kind;
    phase = 'target';
    render('Escolha um inimigo destacado em vermelho.');
  }

  function waitTurn() {
    if (locked || !active || active.team !== 'ally' || phase !== 'action') return;
    locked = true;
    render(`${active.name} encerrou o turno.`);
    schedule(() => {
      locked = false;
      nextTurn();
    }, 250);
  }

  function cancelAction() {
    if (locked || phase !== 'target') return;
    phase = 'action';
    action = '';
    render('Ação cancelada. Escolha novamente.');
  }

  function finishBattle(won) {
    locked = true;
    phase = 'finished';
    element('resultTitle').textContent = won ? 'VITÓRIA' : 'DERROTA';
    element('resultText').textContent = won ? 'O Farol resiste e o vale permanece iluminado!' : 'A luz do Farol se apagou. Tente novamente.';
    element('result').classList.remove('hidden');
    render('Batalha encerrada.');
  }

  function render(message) {
    if (message) element('message').textContent = message;
    const board = element('board');
    board.replaceChildren();

    for (let y = 0; y < BOARD_SIZE; y += 1) {
      for (let x = 0; x < BOARD_SIZE; x += 1) {
        const key = positionKey(x, y);
        const tile = document.createElement('button');
        tile.type = 'button';
        tile.className = `tile${rocks.has(key) ? ' rock' : moss.has(key) ? ' moss' : ''}`;
        tile.setAttribute('aria-label', `Casa ${x + 1}, ${y + 1}`);
        if (active?.team === 'ally' && phase === 'move' && reachable.has(key)) tile.classList.add('move');

        const unit = occupantAt(x, y);
        const range = active ? (action === 'skill' ? active.skill.range : active.range) : 0;
        if (phase === 'target' && unit && unit.team !== active.team && distance(active, unit) <= range) tile.classList.add('target');

        if (unit) {
          const pawn = document.createElement('span');
          pawn.className = `unit ${unit.team}${unit === active ? ' active' : ''}`;
          pawn.textContent = unit.name.slice(0, 2).toUpperCase();
          const hpBar = document.createElement('span');
          hpBar.className = 'hp';
          const hpFill = document.createElement('i');
          hpFill.style.width = `${100 * unit.hp / unit.maxHp}%`;
          hpBar.appendChild(hpFill);
          pawn.appendChild(hpBar);
          tile.appendChild(pawn);
        }
        tile.addEventListener('click', () => handleTileClick(x, y));
        board.appendChild(tile);
      }
    }

    if (active) {
      element('active').innerHTML = `<strong class="${active.team}">ATIVO: ${active.name}</strong><br>HP ${active.hp}/${active.maxHp} &nbsp; MP ${active.mp}/${active.maxMp}<br>${active.type.toUpperCase()} • MOV ${active.movement} • ALC ${active.range}`;
      element('skill').textContent = active.skill.name.toUpperCase();
    }
    const canChooseAction = Boolean(active && active.team === 'ally' && phase === 'action' && !locked);
    for (const id of ['attack', 'skill', 'wait']) element(id).disabled = !canChooseAction;
    element('cancel').disabled = locked || phase !== 'target';
    element('order').innerHTML = units
      .filter((unit) => unit.hp > 0)
      .sort((a, b) => b.speed - a.speed)
      .map((unit) => `<div class="${unit.team}">${unit.name} — HP ${unit.hp}</div>`)
      .join('');
  }

  element('start').addEventListener('click', () => {
    element('intro').classList.add('hidden');
    resetGame();
  });
  element('again').addEventListener('click', resetGame);
  element('restart').addEventListener('click', resetGame);
  element('attack').addEventListener('click', () => chooseAction('attack'));
  element('skill').addEventListener('click', () => chooseAction('skill'));
  element('wait').addEventListener('click', waitTurn);
  element('cancel').addEventListener('click', cancelAction);

  render('Clique em Iniciar batalha.');

  // Read-only diagnostics used by the smoke test and useful when reporting bugs.
  globalThis.LumenGame = {
    start: resetGame,
    snapshot: () => ({ active: active?.name || null, phase, locked, livingAllies: living('ally').length, livingEnemies: living('enemy').length, boardCells: element('board').children.length })
  };
})();
