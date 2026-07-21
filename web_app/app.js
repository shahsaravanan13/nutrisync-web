const API_BASE = "http://localhost:8000/api/v1";
let currentUser = null;

// --- ROUTING / VIEW LOGIC ---
function showView(viewId) {
    document.querySelectorAll('.view').forEach(el => el.classList.remove('active'));
    document.getElementById(`view-${viewId}`).classList.add('active');

    // Update active nav link
    document.querySelectorAll('.nav-link').forEach(el => el.classList.remove('active'));
    const link = Array.from(document.querySelectorAll('.nav-link')).find(el => el.textContent.toLowerCase() === viewId);
    if(link) link.classList.add('active');

    if (viewId === 'recipes') loadRecipes();
    if (viewId === 'ingredients') loadIngredients();
    if (viewId === 'dashboard') loadRecipes(true); // Load a few for dashboard
}

// --- AUTH LOGIC ---
function getToken() {
    return localStorage.getItem('nutrisync_token');
}

function setToken(token) {
    localStorage.setItem('nutrisync_token', token);
}

async function checkAuth() {
    const token = getToken();
    if (!token) {
        showAuthScreen('login');
        return;
    }

    try {
        const res = await fetch(`${API_BASE}/auth/me`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        if (res.ok) {
            currentUser = await res.json();
            document.getElementById('app-shell').classList.remove('hidden');
            document.querySelectorAll('.auth-view').forEach(el => el.classList.add('hidden'));
            updateProfileUI();
            showView('dashboard');
        } else {
            logout();
        }
    } catch (e) {
        logout();
    }
}

function showAuthScreen(screen) {
    document.getElementById('app-shell').classList.add('hidden');
    document.querySelectorAll('.auth-view').forEach(el => {
        el.classList.add('hidden');
        el.classList.remove('active');
    });
    
    const target = document.getElementById(`view-${screen}`);
    target.classList.remove('hidden');
    target.classList.add('active');
}

function logout() {
    localStorage.removeItem('nutrisync_token');
    currentUser = null;
    showAuthScreen('login');
}

async function handleLogin() {
    const user = document.getElementById('login-username').value;
    const pass = document.getElementById('login-password').value;
    const err = document.getElementById('login-error');
    const btnText = document.getElementById('login-text');
    const spinner = document.getElementById('login-spinner');
    
    err.classList.add('hidden');
    btnText.classList.add('hidden');
    spinner.classList.remove('hidden');

    const formData = new URLSearchParams();
    formData.append('username', user);
    formData.append('password', pass);

    try {
        const res = await fetch(`${API_BASE}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: formData
        });
        if (res.ok) {
            const data = await res.json();
            setToken(data.access_token);
            await checkAuth();
        } else {
            const errorData = await res.json();
            err.textContent = errorData.detail || 'Login failed';
            err.classList.remove('hidden');
        }
    } catch (e) {
        err.textContent = 'Network error';
        err.classList.remove('hidden');
    } finally {
        btnText.classList.remove('hidden');
        spinner.classList.add('hidden');
    }
}

async function handleRegister() {
    const user = document.getElementById('reg-username').value;
    const email = document.getElementById('reg-email').value;
    const pass = document.getElementById('reg-password').value;
    const err = document.getElementById('register-error');
    const btnText = document.getElementById('reg-text');
    const spinner = document.getElementById('reg-spinner');

    err.classList.add('hidden');
    btnText.classList.add('hidden');
    spinner.classList.remove('hidden');

    try {
        const res = await fetch(`${API_BASE}/auth/register`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username: user, email: email, password: pass })
        });
        if (res.ok) {
            // Auto login after register
            document.getElementById('login-username').value = user;
            document.getElementById('login-password').value = pass;
            await handleLogin();
        } else {
            const errorData = await res.json();
            err.textContent = errorData.detail || 'Registration failed';
            err.classList.remove('hidden');
        }
    } catch (e) {
        err.textContent = 'Network error';
        err.classList.remove('hidden');
    } finally {
        btnText.classList.remove('hidden');
        spinner.classList.add('hidden');
    }
}

// --- PROFILE & UPLOADS ---
function updateProfileUI() {
    if (!currentUser) return;
    
    // Default avatar fallback
    const avatarUrl = currentUser.profile_picture ? 
        `http://localhost:8000${currentUser.profile_picture}` : 
        `https://ui-avatars.com/api/?name=${currentUser.username}&background=2D6A4F&color=fff`;

    document.getElementById('nav-avatar').src = avatarUrl;
    document.getElementById('profile-avatar').src = avatarUrl;
    
    document.getElementById('nav-username').textContent = currentUser.username;
    document.getElementById('profile-name').textContent = currentUser.full_name || currentUser.username;
    document.getElementById('profile-email').textContent = currentUser.email;
    
    const d = new Date(currentUser.created_at);
    document.getElementById('profile-joined').textContent = `Member since ${d.toLocaleDateString()}`;
}

async function handleAvatarUpload(event) {
    const file = event.target.files[0];
    if (!file) return;

    const formData = new FormData();
    formData.append('file', file);

    try {
        const res = await fetch(`${API_BASE}/auth/upload-avatar`, {
            method: 'POST',
            headers: { 'Authorization': `Bearer ${getToken()}` },
            body: formData
        });
        if (res.ok) {
            const data = await res.json();
            currentUser.profile_picture = data.url;
            updateProfileUI();
        } else {
            alert("Upload failed. Make sure it's an image.");
        }
    } catch (e) {
        alert("Upload error.");
    }
}

// --- DATA FETCHING (RECIPES & INGREDIENTS) ---
let searchTimeout = null;

function handleRecipeSearch() {
    clearTimeout(searchTimeout);
    searchTimeout = setTimeout(() => { loadRecipes(); }, 300);
}

function handleIngredientSearch() {
    clearTimeout(searchTimeout);
    searchTimeout = setTimeout(() => { loadIngredients(); }, 300);
}

async function loadRecipes(isDashboard = false) {
    const gridId = isDashboard ? 'dashboard-recipes' : 'recipes-grid';
    const grid = document.getElementById(gridId);
    
    let url = `${API_BASE}/recipes?limit=${isDashboard ? 4 : 50}`;
    if (!isDashboard) {
        const query = document.getElementById('recipe-search').value;
        if (query) url += `&search=${encodeURIComponent(query)}`;
        document.getElementById('recipes-spinner').classList.remove('hidden');
    }
    
    grid.innerHTML = '';

    try {
        const res = await fetch(url, { headers: { 'Authorization': `Bearer ${getToken()}` }});
        if (res.ok) {
            const recipes = await res.json();
            renderRecipes(recipes, grid);
        }
    } finally {
        if (!isDashboard) document.getElementById('recipes-spinner').classList.add('hidden');
    }
}

async function loadIngredients() {
    const grid = document.getElementById('ingredients-grid');
    const query = document.getElementById('ingredient-search').value;
    let url = `${API_BASE}/ingredients?limit=50`;
    if (query) url += `&search=${encodeURIComponent(query)}`;
    
    document.getElementById('ingredients-spinner').classList.remove('hidden');
    grid.innerHTML = '';

    try {
        const res = await fetch(url, { headers: { 'Authorization': `Bearer ${getToken()}` }});
        if (res.ok) {
            const ingredients = await res.json();
            renderIngredients(ingredients, grid);
        }
    } finally {
        document.getElementById('ingredients-spinner').classList.add('hidden');
    }
}

function renderRecipes(recipes, container) {
    if (recipes.length === 0) {
        container.innerHTML = '<p style="grid-column:1/-1; text-align:center; color:var(--text2);">No recipes found.</p>';
        return;
    }
    
    recipes.forEach(r => {
        const card = document.createElement('div');
        card.className = 'recipe-card';
        card.innerHTML = `
            <img src="${r.image_url}" class="recipe-img" />
            <div class="recipe-content">
                <h3 class="recipe-title">${r.title}</h3>
                <div class="recipe-meta">
                    <span>⏱ ${r.prep_time + r.cook_time} mins</span>
                    <span>🔥 ${r.calories} kcal</span>
                </div>
            </div>
        `;
        container.appendChild(card);
    });
}

function renderIngredients(ingredients, container) {
    if (ingredients.length === 0) {
        container.innerHTML = '<p style="grid-column:1/-1; text-align:center; color:var(--text2);">No ingredients found.</p>';
        return;
    }
    
    ingredients.forEach(i => {
        const card = document.createElement('div');
        card.className = 'ingredient-card';
        card.innerHTML = `
            <img src="${i.image_url}" class="ingredient-img" />
            <div class="ingredient-info">
                <h4>${i.name}</h4>
                <p>${i.category}</p>
            </div>
        `;
        container.appendChild(card);
    });
}

// INIT
window.onload = () => {
    checkAuth();
};
