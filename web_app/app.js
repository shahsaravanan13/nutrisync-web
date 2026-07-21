'use strict';

/* ════════════════════════════════════════════════════════
   NutriSync – App Logic v2
   Backend: http://127.0.0.1:8000
════════════════════════════════════════════════════════ */

const API = 'http://127.0.0.1:8000';

// ── STATE ────────────────────────────────────────────────
let ingredients   = [];
let savedRecipes  = [];
let currentRecipe = null;
let chatHistory   = [];
let profile = { name: 'Chef', bio: 'Nutrition Enthusiast', dietTag: 'Healthy Eater' };
let userGoal = { goal: 'Weight Loss', calorieTarget: 2000 };
let recipesGenerated = 0;
let isGenerating = false;
let isChatBusy   = false;
let recognition  = null;
let isListening  = false;
let demoIdx      = 0;

const GOALS = ['Weight Loss','Muscle Gain','Maintenance','Improve Immunity','Better Digestion','Athletic Performance'];

const DEMO_RECIPES = [
  { name:'Asian Noodle Bowl',    cal:'380 kcal', time:'15 min', emoji:'🍜', color:'#4A7C59' },
  { name:'Lentil Curry Soup',    cal:'290 kcal', time:'25 min', emoji:'🍛', color:'#B8860B' },
  { name:'Grilled Chicken Wrap', cal:'420 kcal', time:'12 min', emoji:'🌯', color:'#8B4513' },
  { name:'Veggie Stir Fry',      cal:'310 kcal', time:'18 min', emoji:'🥦', color:'#2E8B57' },
  { name:'Quinoa Power Bowl',    cal:'350 kcal', time:'20 min', emoji:'🥗', color:'#2D6A4F' },
  { name:'Salmon & Greens',      cal:'430 kcal', time:'22 min', emoji:'🐟', color:'#4682B4' },
];

const CHAT_DEMOS = [
  'For balanced nutrition, aim for half your plate as vegetables, a quarter lean protein, and a quarter whole grains.',
  'Getting 25–30g of protein per meal supports muscle health and keeps you full longer.',
  'Hydration matters — try to drink 8 glasses of water daily, more if you exercise.',
  'Meal prepping on Sundays saves time and makes healthy eating much easier during the week!',
  'Whole, minimally processed foods are always your best choice for long-term health.',
  'A moderate calorie deficit of 300–500 kcal per day is safe and sustainable for weight loss.',
  'High-fibre foods like legumes, oats, and vegetables help you stay full and support gut health.',
];

// ── BOOT ────────────────────────────────────────────────
window.addEventListener('DOMContentLoaded', () => {
  loadStorage();
  setGreeting();
  renderHomeRecipes();
  setupChatInput();
  setupIngredientInput();
  initSpeech();

  setTimeout(() => {
    const loggedIn = localStorage.getItem('ns_loggedIn') === 'true';
    showScreen(loggedIn ? 'app' : 'login');
  }, 2900);
});

function loadStorage() {
  try {
    const p = localStorage.getItem('ns_profile'); if (p) profile = JSON.parse(p);
    const g = localStorage.getItem('ns_goal');    if (g) userGoal = JSON.parse(g);
    const s = localStorage.getItem('ns_saved');   if (s) savedRecipes = JSON.parse(s);
    const n = localStorage.getItem('ns_gen');     if (n) recipesGenerated = parseInt(n);
    if (localStorage.getItem('ns_dark') === 'true') document.body.classList.add('dark');
  } catch(e) {}
}

function saveStorage() {
  localStorage.setItem('ns_profile', JSON.stringify(profile));
  localStorage.setItem('ns_goal',    JSON.stringify(userGoal));
  localStorage.setItem('ns_saved',   JSON.stringify(savedRecipes));
  localStorage.setItem('ns_gen',     String(recipesGenerated));
}

// ── SCREEN NAVIGATION ────────────────────────────────────
function showScreen(name) {
  document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
  const s = document.getElementById('screen-' + name);
  if (s) s.classList.add('active');
  if (name === 'app') switchPage('home');
}

// ── PAGE NAVIGATION (inside app) ────────────────────────
function switchPage(pg) {
  document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
  const el = document.getElementById('page-' + pg);
  if (el) el.classList.add('active');
  document.querySelectorAll('.nav-btn').forEach(b => b.classList.toggle('active', b.dataset.pg === pg));
  if (pg === 'saved')   renderSaved();
  if (pg === 'profile') renderProfile();
  if (pg === 'chat')    initChat();
}

// ── MODAL SYSTEM ────────────────────────────────────────
function openModal(name) {
  const el = document.getElementById('modal-' + name);
  if (!el) return;
  el.style.display = 'flex';
  if (name === 'edit-profile')  fillEditProfile();
  if (name === 'nutrition-goal') fillGoalModal();
  if (name === 'recipe-history') renderHistory();
  if (name === 'recommended')    renderRecommended();
}

function closeModal(name) {
  const el = document.getElementById('modal-' + name);
  if (el) el.style.display = 'none';
}

// ── GREETING ────────────────────────────────────────────
function setGreeting() {
  const h = new Date().getHours();
  const txt = h < 12 ? 'Good Morning,' : h < 17 ? 'Good Afternoon,' : 'Good Evening,';
  const el = document.getElementById('greeting-h1');
  if (el) el.textContent = txt;
}

// ── HOME RECIPES ─────────────────────────────────────────
function renderHomeRecipes() {
  const g = document.getElementById('home-recipe-grid');
  if (g) g.innerHTML = DEMO_RECIPES.slice(0,4).map((r,i) => recipeCardHTML(r,i)).join('');
}

function recipeCardHTML(r, i) {
  return `<div class="rcard" onclick="openDemoRecipe(${i})">
    <div class="rcard-img" style="background:${r.color}">${r.emoji}</div>
    <div class="rcard-body">
      <div class="rcard-name">${r.name}</div>
      <div class="rcard-meta">🔥 ${r.cal} <span>•</span> ⏱ ${r.time}</div>
    </div>
  </div>`;
}

function openDemoRecipe(i) {
  const r = DEMO_RECIPES[i];
  openRecipeModal({
    recipe_name: r.name,
    total_time: parseInt(r.time),
    ingredients_used: [
      { name:'Main Ingredient', quantity:'200g' },
      { name:'Fresh Herbs', quantity:'To taste' },
      { name:'Olive Oil', quantity:'1 tbsp' },
    ],
    steps: [
      { step_number:1, instruction:'Prepare and clean all ingredients. Chop as needed.' },
      { step_number:2, instruction:'Heat oil in a pan over medium heat and start cooking.' },
      { step_number:3, instruction:'Combine everything, season well, plate and serve warm.' },
    ],
    nutrition_facts: { calories: parseInt(r.cal), protein:18, carbohydrates:32, fat:12, fiber:5 },
  });
}

function openFeaturedRecipe() {
  openRecipeModal({
    recipe_name: 'Emerald Garden Buddha Bowl',
    total_time: 15,
    ingredients_used: [
      { name:'Quinoa', quantity:'1 cup' },
      { name:'Mixed Greens', quantity:'2 cups' },
      { name:'Avocado', quantity:'1 large' },
      { name:'Olive Oil', quantity:'1 tbsp' },
    ],
    steps: [
      { step_number:1, instruction:'Cook quinoa in 2 cups water for 12 minutes until fluffy.' },
      { step_number:2, instruction:'Arrange greens, quinoa and sliced avocado in a bowl.' },
      { step_number:3, instruction:'Drizzle with olive oil, season with salt and pepper and serve.' },
    ],
    nutrition_facts: { calories:320, protein:12, carbohydrates:45, fat:8, fiber:6 },
  });
}

// ── AUTH ─────────────────────────────────────────────────
function togglePwd(id, btn) {
  const inp = document.getElementById(id);
  if (!inp) return;
  inp.type = inp.type === 'password' ? 'text' : 'password';
  btn.textContent = inp.type === 'password' ? '👁' : '🙈';
}

async function handleLogin() {
  const email = document.getElementById('login-email')?.value?.trim();
  const pass  = document.getElementById('login-password')?.value?.trim();
  if (!email || !pass) { snack('Please fill in both fields'); return; }

  const btnText = document.getElementById('login-btn-text');
  const spin    = document.getElementById('login-spinner');
  if (btnText) btnText.classList.add('hidden');
  if (spin)    spin.classList.remove('hidden');

  await sleep(900);

  localStorage.setItem('ns_loggedIn', 'true');
  localStorage.setItem('ns_email', email);
  if (btnText) btnText.classList.remove('hidden');
  if (spin)    spin.classList.add('hidden');
  showScreen('app');
}

function handleSignup() {
  const name  = document.getElementById('signup-name')?.value?.trim();
  const email = document.getElementById('signup-email')?.value?.trim();
  const pass  = document.getElementById('signup-password')?.value?.trim();
  if (!name || !email || !pass) { snack('Please fill in all fields'); return; }
  profile.name = name;
  saveStorage();
  localStorage.setItem('ns_loggedIn', 'true');
  showScreen('app');
}

function confirmLogout() { openModal('logout'); }
function doLogout() {
  localStorage.setItem('ns_loggedIn', 'false');
  closeModal('logout');
  showScreen('login');
}

// ── INPUT PAGE ────────────────────────────────────────────
function setupIngredientInput() {
  const ta = document.getElementById('ingredient-input');
  if (!ta) return;
  ta.addEventListener('keydown', e => {
    if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); addIngredient(); }
  });
}

function addIngredient() {
  const inp = document.getElementById('ingredient-input');
  if (!inp) return;
  const raw = inp.value.trim();
  if (!raw) { snack('Type an ingredient first'); return; }
  raw.split(',').map(s => s.trim()).filter(Boolean).forEach(item => {
    ingredients.push({ name: item, cat: guessCategory(item), cal: guessCalories(item) });
  });
  inp.value = '';
  renderIngredients();
}

function guessCategory(t) {
  t = t.toLowerCase();
  if (/chicken|beef|fish|egg|salmon|shrimp|turkey|pork|lamb/.test(t)) return 'Proteins';
  if (/rice|bread|pasta|noodle|oat|wheat|flour|potato/.test(t)) return 'Carbs';
  if (/tomato|onion|garlic|pepper|carrot|broccoli|spinach|lettuce|cabbage/.test(t)) return 'Vegetables';
  if (/apple|banana|mango|berry|orange|lemon|lime/.test(t)) return 'Fruits';
  if (/oil|butter|cheese|cream|milk|yogurt/.test(t)) return 'Dairy/Fats';
  return 'Other';
}

function guessCalories(t) {
  t = t.toLowerCase();
  if (t.includes('chicken')) return 239;
  if (t.includes('egg'))     return 155;
  if (t.includes('rice'))    return 130;
  if (t.includes('salmon'))  return 208;
  if (t.includes('bread'))   return 265;
  if (t.includes('cheese'))  return 402;
  if (t.includes('banana'))  return 89;
  if (t.includes('tomato'))  return 18;
  if (t.includes('milk'))    return 42;
  return 55;
}

function catEmoji(c) {
  return { Proteins:'🥚', Carbs:'🍞', Vegetables:'🥦', Fruits:'🍎', 'Dairy/Fats':'🧈', Other:'🍽' }[c] || '🍽';
}

function renderIngredients() {
  const sec   = document.getElementById('ing-section');
  const list  = document.getElementById('ing-list');
  const badge = document.getElementById('ing-badge');
  if (!sec || !list) return;
  if (ingredients.length === 0) { sec.style.display = 'none'; return; }
  sec.style.display = 'block';
  if (badge) badge.textContent = ingredients.length + ' items';
  list.innerHTML = ingredients.map((ing, i) => `
    <div class="ing-tile" style="animation-delay:${i*40}ms">
      <div class="ing-cat-ico">${catEmoji(ing.cat)}</div>
      <div class="ing-info">
        <div class="ing-name">${ing.name}</div>
        <div class="ing-meta">${ing.cat} • ~${ing.cal} kcal</div>
      </div>
      <button class="ing-del" onclick="removeIng(${i})">🗑</button>
    </div>`).join('');
}

function removeIng(i) {
  ingredients.splice(i, 1);
  renderIngredients();
}

// ── RECIPE GENERATION ────────────────────────────────────
function makeDemoRecipe(names) {
  return {
    recipe_name: `Chef's ${cap(names[0] || 'Mixed')} Special`,
    total_time: 20,
    ingredients_used: names.map((n,i) => ({ name:n, quantity: i===0?'200g':i===1?'1 cup':'2 tbsp' })),
    steps: [
      { step_number:1, instruction:`Prepare all ingredients: ${names.join(', ')}. Wash, peel, and chop as needed.` },
      { step_number:2, instruction:`Heat oil in a pan over medium heat. Add ${names[0]} and cook for 4 minutes.` },
      { step_number:3, instruction:`Add remaining ingredients, stir well and cook for 8–10 more minutes.` },
      { step_number:4, instruction:`Season with salt and pepper. Plate elegantly and serve warm.` },
    ],
    nutrition_facts: {
      calories: 360 + names.length * 20,
      protein: 22, carbohydrates: 34, fat: 11, fiber: 5,
    },
    _demo: true,
  };
}

async function generateRecipe() {
  if (isGenerating) return;
  if (ingredients.length === 0) { snack('Add at least one ingredient first'); return; }
  isGenerating = true;

  const btn  = document.getElementById('gen-btn');
  const txt  = document.getElementById('gen-text');
  const spin = document.getElementById('gen-spinner');
  if (btn)  btn.disabled = true;
  if (txt)  txt.textContent = 'Generating...';
  if (spin) spin.classList.remove('hidden');

  const names = ingredients.map(i => i.name);

  try {
    const res = await Promise.race([
      fetch(`${API}/api/v1/generate-recipe`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ ingredients: names, dietary_preferences: null }),
      }),
      new Promise((_, rej) => setTimeout(() => rej(new Error('timeout')), 120000)),
    ]);

    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const data = await res.json();
    addToHistory(data.recipe_name, data.nutrition_facts);
    openRecipeModal(data);
  } catch(e) {
    console.warn('Backend unreachable, using demo:', e.message);
    const demo = makeDemoRecipe(names);
    addToHistory(demo.recipe_name, demo.nutrition_facts);
    openRecipeModal(demo);
    snack('⚠️ Backend offline — showing demo recipe');
  } finally {
    isGenerating = false;
    if (btn)  btn.disabled = false;
    if (txt)  txt.textContent = '✨ Generate AI Recipe';
    if (spin) spin.classList.add('hidden');
  }
}

// ── RECIPE MODAL ─────────────────────────────────────────
function openRecipeModal(recipe) {
  currentRecipe = recipe;
  const name  = recipe.recipe_name || recipe.recipeName || 'Recipe';
  const time  = recipe.total_time  || recipe.totalTime  || 20;
  const nf    = recipe.nutrition_facts || recipe.nutritionFacts || {};
  const ings  = recipe.ingredients_used || recipe.ingredientsUsed || [];
  const steps = recipe.steps || [];
  const img   = recipe.image_url || recipe.imageUrl || '';

  // Hero
  const hero = document.getElementById('recipe-hero');
  if (hero) {
    if (img) {
      hero.style.backgroundImage = `url('${img}')`;
      hero.style.backgroundSize  = 'cover';
      hero.style.backgroundPosition = 'center';
    } else {
      hero.style.backgroundImage = '';
      hero.style.background = 'linear-gradient(135deg,#1B4332,#52B788)';
    }
  }
  setText('hero-name', name);
  setText('hero-time', time + ' MIN');

  // Save button
  const isSaved = savedRecipes.some(r => (r.recipe_name||r.recipeName) === name);
  const saveBtn = document.getElementById('save-btn');
  if (saveBtn) saveBtn.style.background = isSaved ? 'rgba(245,158,11,.85)' : 'rgba(0,0,0,.3)';

  // Macros
  const mg = document.getElementById('macro-grid');
  if (mg) mg.innerHTML = [
    { lbl:'CALORIES', val: Math.round(nf.calories||0),     sub:'total kcal',     color:'#EC6E30' },
    { lbl:'PROTEIN',  val: Math.round(nf.protein||0)+'g',  sub:'per serving',    color:'#2D6A4F' },
    { lbl:'CARBS',    val: Math.round(nf.carbohydrates||0)+'g', sub:'complex',   color:'#F59E0B' },
    { lbl:'FAT',      val: Math.round(nf.fat||0)+'g',      sub:'healthy fats',   color:'#EF4444' },
  ].map(m => `<div class="macro-card" style="background:${m.color}12;border:1.5px solid ${m.color}20">
    <div class="macro-lbl" style="color:${m.color}">${m.lbl}</div>
    <div class="macro-val">${m.val}</div>
    <div class="macro-sub">${m.sub}</div>
  </div>`).join('');

  // Ingredients
  const il = document.getElementById('modal-ings');
  const ib = document.getElementById('ing-count-badge');
  if (il) il.innerHTML = ings.map(ing => {
    const n = ing.name || String(ing);
    const q = ing.quantity || '';
    return `<div class="modal-ing">
      <div class="modal-ing-ico">${ingEmoji(n)}</div>
      <div class="modal-ing-name">${n}</div>
      <div class="modal-ing-qty">${q}</div>
    </div>`;
  }).join('');
  if (ib) ib.textContent = ings.length + ' items';

  // Steps
  const sl = document.getElementById('modal-steps');
  if (sl) sl.innerHTML = steps.map((step, i) => {
    const num  = step.step_number || step.stepNumber || (i+1);
    const inst = step.instruction || String(step);
    const last = i === steps.length - 1;
    return `<div class="step-item">
      <div class="step-num-col">
        <div class="step-num">${num}</div>
        ${!last ? '<div class="step-line"></div>' : ''}
      </div>
      <div class="step-content">
        <div class="step-lbl">Step ${num}</div>
        <div class="step-txt">${inst}</div>
      </div>
    </div>`;
  }).join('');

  openModal('recipe');
}

function ingEmoji(n) {
  n = (n||'').toLowerCase();
  if (/salmon|fish|shrimp/.test(n)) return '🐟';
  if (/chicken|turkey|beef|pork/.test(n)) return '🍗';
  if (/egg/.test(n)) return '🥚';
  if (/lemon|lime/.test(n)) return '🍋';
  if (/garlic|onion/.test(n)) return '🧅';
  if (/tomato/.test(n)) return '🍅';
  if (/herb|basil|parsley|thyme/.test(n)) return '🌿';
  if (/oil|butter/.test(n)) return '🫙';
  if (/rice|pasta|noodle/.test(n)) return '🍚';
  if (/milk|cream|cheese|yogurt/.test(n)) return '🥛';
  if (/avocado/.test(n)) return '🥑';
  if (/broccoli|spinach|kale/.test(n)) return '🥦';
  if (/carrot/.test(n)) return '🥕';
  return '🍽';
}

function toggleSave() {
  if (!currentRecipe) return;
  const name = currentRecipe.recipe_name || currentRecipe.recipeName;
  const idx  = savedRecipes.findIndex(r => (r.recipe_name||r.recipeName) === name);
  const btn  = document.getElementById('save-btn');
  if (idx >= 0) {
    savedRecipes.splice(idx, 1);
    snack('Removed from saved');
    if (btn) btn.style.background = 'rgba(0,0,0,.3)';
  } else {
    savedRecipes.unshift(currentRecipe);
    snack('Recipe saved! 🎉');
    if (btn) btn.style.background = 'rgba(245,158,11,.85)';
  }
  saveStorage();
  const ps = document.getElementById('pstat-saved');
  if (ps) ps.textContent = savedRecipes.length;
}

// ── SAVED PAGE ────────────────────────────────────────────
function renderSaved() {
  const list  = document.getElementById('saved-list');
  const empty = document.getElementById('saved-empty');
  const sub   = document.getElementById('saved-sub');
  if (!list) return;
  if (sub) sub.textContent = savedRecipes.length + ' recipe' + (savedRecipes.length!==1?'s':'') + ' saved';
  if (savedRecipes.length === 0) {
    list.innerHTML = '';
    if (empty) empty.style.display = 'block';
    return;
  }
  if (empty) empty.style.display = 'none';
  const grads = [['#2D6A4F','#40916C'],['#1B4332','#52B788'],['#0D3B2E','#2D6A4F']];
  list.innerHTML = savedRecipes.map((r,i) => {
    const name = r.recipe_name || r.recipeName || 'Recipe';
    const nf   = r.nutrition_facts || r.nutritionFacts || {};
    const t    = r.total_time || r.totalTime || 0;
    const g    = grads[i%grads.length];
    const tags = [];
    if ((nf.carbohydrates||0) < 30) tags.push('Low Carb');
    if ((nf.protein||0) > 25)       tags.push('High Protein');
    if ((nf.calories||0) < 300)     tags.push('Low Cal');
    return `<div class="saved-card" onclick="openSavedRecipe(${i})" style="animation-delay:${i*70}ms">
      <div class="saved-card-accent" style="background:linear-gradient(135deg,${g[0]},${g[1]})">🍽</div>
      <div class="saved-card-body">
        <div class="saved-name">${name}</div>
        <div class="saved-meta">🔥 ${Math.round(nf.calories||0)} kcal <span>•</span> ⏱ ${t} min</div>
        ${tags.length?`<div class="saved-tags">${tags.map(t=>`<span class="mini-chip">${t}</span>`).join('')}</div>`:''}
      </div>
      <span class="saved-chev">›</span>
    </div>`;
  }).join('');
}

function openSavedRecipe(i) {
  openRecipeModal(savedRecipes[i]);
}

// ── PROFILE ───────────────────────────────────────────────
function renderProfile() {
  setText('profile-name', profile.name||'Chef');
  setText('profile-bio', `${profile.bio||'Nutrition Enthusiast'} • ${profile.dietTag||'Healthy Eater'}`);
  setText('profile-avatar', (profile.name||'C')[0].toUpperCase());
  setText('pstat-gen', recipesGenerated);
  setText('pstat-saved', savedRecipes.length);
  setText('pstat-days', localStorage.getItem('ns_days')||'1');
  setText('pstat-cal', userGoal.calorieTarget||2000);

  const chips = document.getElementById('goal-chips');
  if (chips) chips.innerHTML = GOALS.map(g => `<div class="g-chip ${g===userGoal.goal?'sel':''}">${g}</div>`).join('');
}

function fillEditProfile() {
  const n = document.getElementById('edit-name'); if (n) n.value = profile.name||'';
  const b = document.getElementById('edit-bio');  if (b) b.value = profile.bio||'';
  const d = document.getElementById('edit-diet'); if (d) d.value = profile.dietTag||'';
  const a = document.getElementById('edit-avatar'); if (a) a.textContent = (profile.name||'C')[0].toUpperCase();
}

function saveProfile() {
  profile.name    = document.getElementById('edit-name')?.value?.trim() || profile.name;
  profile.bio     = document.getElementById('edit-bio')?.value?.trim()  || profile.bio;
  profile.dietTag = document.getElementById('edit-diet')?.value?.trim() || profile.dietTag;
  saveStorage();
  closeModal('edit-profile');
  renderProfile();
  snack('Profile updated!');
}

function fillGoalModal() {
  const chips = document.getElementById('goal-sel');
  if (chips) chips.innerHTML = GOALS.map(g => `<div class="g-chip ${g===userGoal.goal?'sel':''}" onclick="selectGoal('${g}',this)">${g}</div>`).join('');
  const ci = document.getElementById('cal-inp'); if (ci) ci.value = userGoal.calorieTarget||2000;
}

function selectGoal(g, el) {
  userGoal.goal = g;
  document.querySelectorAll('#goal-sel .g-chip').forEach(c => c.classList.remove('sel'));
  el.classList.add('sel');
}

function saveGoal() {
  const cal = parseInt(document.getElementById('cal-inp')?.value)||2000;
  userGoal.calorieTarget = cal;
  saveStorage();
  closeModal('nutrition-goal');
  snack('Goal updated!');
}

function toggleDark(on) {
  document.body.classList.toggle('dark', on);
  localStorage.setItem('ns_dark', on);
}

function shareApp() {
  if (navigator.share) {
    navigator.share({ title:'NutriSync', text:'AI-powered nutrition app!', url: location.href });
  } else {
    navigator.clipboard?.writeText(location.href).then(() => snack('Link copied!'));
  }
}

// ── HISTORY ───────────────────────────────────────────────
function addToHistory(name, nf) {
  if (!name) return;
  const h = JSON.parse(localStorage.getItem('ns_history')||'[]');
  h.unshift({ name, date: new Date().toLocaleDateString(), cal: Math.round((nf||{}).calories||0) });
  localStorage.setItem('ns_history', JSON.stringify(h.slice(0,30)));
  recipesGenerated++;
  saveStorage();
}

function renderHistory() {
  const list  = document.getElementById('hist-list');
  const empty = document.getElementById('hist-empty');
  const h = JSON.parse(localStorage.getItem('ns_history')||'[]');
  if (!list) return;
  if (h.length === 0) {
    list.innerHTML = '';
    if (empty) empty.style.display = 'block';
    return;
  }
  if (empty) empty.style.display = 'none';
  list.innerHTML = h.map((r,i) => `<div class="hist-item" style="animation-delay:${i*50}ms">
    <div class="hist-ico">🍽</div>
    <div><div class="hist-name">${r.name}</div><div class="hist-meta">${r.date} • ${r.cal} kcal</div></div>
  </div>`).join('');
}

function renderRecommended() {
  const g = document.getElementById('rec-grid');
  if (g) g.innerHTML = DEMO_RECIPES.map((r,i) => recipeCardHTML(r,i)).join('');
}

// ── SEARCH ────────────────────────────────────────────────
function runSearch() {
  const q   = document.getElementById('search-inp')?.value?.trim().toLowerCase();
  const res = document.getElementById('search-res');
  if (!res) return;
  if (!q) { res.innerHTML = '<p class="hint-text">Start typing to search...</p>'; return; }
  const matches = [...DEMO_RECIPES, ...savedRecipes.map(r => ({ name: r.recipe_name||r.recipeName||'', cal:'–', time:'–', emoji:'🍽', _r:r }))]
    .filter(r => r.name.toLowerCase().includes(q));
  if (!matches.length) { res.innerHTML = '<p class="hint-text">No results found.</p>'; return; }
  res.innerHTML = matches.map((r,i) => `<div class="s-result" onclick="openSearchRes(${i})">
    <span style="font-size:24px">${r.emoji||'🍽'}</span>
    <div>
      <div style="font-size:14px;font-weight:600;color:var(--text1)">${r.name}</div>
      <div style="font-size:12px;color:var(--text3)">${r.cal} • ${r.time}</div>
    </div>
  </div>`).join('');
  window._sr = matches;
}

function openSearchRes(i) {
  const r = window._sr?.[i];
  if (!r) return;
  closeModal('search');
  if (r._r) { openRecipeModal(r._r); return; }
  const idx = DEMO_RECIPES.findIndex(d => d.name === r.name);
  if (idx >= 0) openDemoRecipe(idx);
}

// ── CHAT ─────────────────────────────────────────────────
function setupChatInput() {
  const ta = document.getElementById('chat-input');
  if (!ta) return;
  ta.addEventListener('input', () => {
    ta.style.height = 'auto';
    ta.style.height = Math.min(ta.scrollHeight, 100) + 'px';
  });
  ta.addEventListener('keydown', e => {
    if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendChat(); }
  });
}

function initChat() {
  const msgs = document.getElementById('chat-msgs');
  if (!msgs || msgs.children.length > 0) return;
  addBubble('bot', 'Hi Chef! 👋 I\'m NutriBot, your AI nutrition assistant. Ask me anything about healthy eating, meal planning, or nutrition goals!');
}

function addBubble(role, text) {
  const msgs = document.getElementById('chat-msgs');
  if (!msgs) return;
  const d = document.createElement('div');
  d.className = 'bubble ' + role;
  d.textContent = text;
  msgs.appendChild(d);
  msgs.scrollTop = msgs.scrollHeight;
}

function showTyping() {
  const msgs = document.getElementById('chat-msgs');
  if (!msgs) return;
  const d = document.createElement('div');
  d.id = 'typing-ind';
  d.className = 'typing-bubble';
  d.innerHTML = '<div class="dots"><span></span><span></span><span></span></div>';
  msgs.appendChild(d);
  msgs.scrollTop = msgs.scrollHeight;
}
function hideTyping() { document.getElementById('typing-ind')?.remove(); }

async function sendChat() {
  if (isChatBusy) return;
  const inp = document.getElementById('chat-input');
  const msg = inp?.value?.trim();
  if (!msg) return;
  inp.value = '';
  inp.style.height = 'auto';
  addBubble('user', msg);
  chatHistory.push({ role:'user', content: msg });
  isChatBusy = true;
  const btn = document.getElementById('chat-send');
  if (btn) btn.style.opacity = '.5';
  showTyping();

  try {
    const res = await Promise.race([
      fetch(`${API}/api/v1/chat`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ message: msg, history: chatHistory.slice(-10) }),
      }),
      new Promise((_, rej) => setTimeout(() => rej(new Error('timeout')), 60000)),
    ]);
    if (!res.ok) throw new Error('HTTP ' + res.status);
    const data = await res.json();
    const reply = data.response || data.message || "I'm thinking, try again!";
    hideTyping();
    addBubble('bot', reply);
    chatHistory.push({ role:'assistant', content: reply });
  } catch(e) {
    await sleep(1000);
    const reply = CHAT_DEMOS[demoIdx % CHAT_DEMOS.length];
    demoIdx++;
    hideTyping();
    addBubble('bot', reply);
    chatHistory.push({ role:'assistant', content: reply });
  } finally {
    isChatBusy = false;
    if (btn) btn.style.opacity = '1';
  }
}

// ── SPEECH ────────────────────────────────────────────────
function initSpeech() {
  const SR = window.SpeechRecognition || window.webkitSpeechRecognition;
  if (!SR) return;
  recognition = new SR();
  recognition.continuous = true;
  recognition.interimResults = true;
  recognition.onresult = e => {
    let t = '';
    for (let i = e.resultIndex; i < e.results.length; i++) t += e.results[i][0].transcript;
    const inp = document.getElementById('ingredient-input');
    if (inp) inp.value = t;
    const lbl = document.getElementById('mic-hint');
    if (lbl) lbl.textContent = t || 'Speak your ingredients…';
  };
  recognition.onerror = () => stopMic();
  recognition.onend   = () => { if (isListening) recognition.start(); };
}

function toggleMic() {
  if (!recognition) { snack('Speech recognition not supported in this browser'); return; }
  isListening ? stopMic() : startMic();
}

function startMic() {
  isListening = true;
  recognition.start();
  const card = document.getElementById('mic-card');
  const btn  = document.getElementById('mic-btn');
  const lbl  = document.getElementById('mic-label');
  const hint = document.getElementById('mic-hint');
  if (card) card.classList.add('listening');
  if (btn)  { btn.textContent = '⏹'; btn.style.background = '#EF4444'; }
  if (lbl)  lbl.textContent = 'Listening…';
  if (hint) hint.textContent = 'Speak your ingredients…';
}

function stopMic() {
  isListening = false;
  if (recognition) recognition.stop();
  const card = document.getElementById('mic-card');
  const btn  = document.getElementById('mic-btn');
  const lbl  = document.getElementById('mic-label');
  const hint = document.getElementById('mic-hint');
  if (card) card.classList.remove('listening');
  if (btn)  { btn.textContent = '🎤'; btn.style.background = 'var(--green)'; }
  if (lbl)  lbl.textContent = 'Tap to Speak';
  if (hint) hint.textContent = 'Say your ingredients aloud';
  const inp = document.getElementById('ingredient-input');
  if (inp?.value?.trim()) addIngredient();
}

// ── UTILS ─────────────────────────────────────────────────
function snack(msg, duration=3000) {
  const el = document.getElementById('snackbar');
  if (!el) return;
  el.textContent = msg;
  el.style.display = 'block';
  clearTimeout(el._t);
  el._t = setTimeout(() => el.style.display = 'none', duration);
}

function setText(id, val) {
  const el = document.getElementById(id);
  if (el) el.textContent = val;
}

function cap(s) { return s ? s.charAt(0).toUpperCase() + s.slice(1) : s; }

function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }
