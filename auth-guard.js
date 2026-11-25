(function () {
  const supabaseUrl = "https://ervlgxziksargjncwogu.supabase.co";
  const supabaseKey = "sb_publishable_RmLqHIC7mZ_YnVJyxFHQxg_4ziCyTgl";

  document.documentElement.classList.add("auth-pending");

  const style = document.createElement("style");
  style.textContent = `
    html.auth-pending body { visibility: hidden; }
    .site-auth-gate[hidden], .site-auth-sign-out[hidden] { display: none; }
    .site-auth-gate {
      position: fixed; inset: 0; z-index: 99999; display: grid; place-items: center;
      padding: 24px; background: #edf2ef; color: #1d2b24;
      font: 16px/1.5 system-ui, sans-serif;
    }
    .site-auth-card {
      width: min(100%, 400px); padding: 32px; border: 1px solid #d5dfd9;
      border-radius: 8px; background: #fff; box-shadow: 0 18px 50px #173b2b18;
    }
    .site-auth-card h1 { margin: 0 0 8px; font-size: 25px; }
    .site-auth-card p { margin: 0 0 22px; color: #5d6c63; }
    .site-auth-card label { display: block; margin: 14px 0 5px; font-size: 14px; font-weight: 650; }
    .site-auth-card input {
      width: 100%; padding: 11px 12px; border: 1px solid #bdcbc2; border-radius: 5px;
      background: #fff; color: inherit; font: inherit;
    }
    .site-auth-card button, .site-auth-sign-out {
      border: 0; border-radius: 5px; background: #226344; color: #fff;
      font: inherit; font-weight: 650; cursor: pointer;
    }
    .site-auth-card button { width: 100%; margin-top: 20px; padding: 11px 14px; }
    .site-auth-card button:disabled { opacity: .65; cursor: wait; }
    .site-auth-error { min-height: 24px; margin: 12px 0 0 !important; color: #a42e2e !important; font-size: 14px; }
    .site-auth-sign-out { position: fixed; top: 12px; right: 12px; z-index: 1000; padding: 8px 12px; }
    @media (max-width: 480px) { .site-auth-card { padding: 24px; } }
  `;
  document.head.append(style);

  function initializeAuth() {
    const gate = document.createElement("section");
    gate.className = "site-auth-gate";
    gate.setAttribute("aria-labelledby", "site-auth-title");
    gate.hidden = true;
    gate.innerHTML = `
      <div class="site-auth-card">
        <h1 id="site-auth-title">Inicia la sessió</h1>
        <p>Entra amb el teu compte autoritzat per continuar.</p>
        <form>
          <label for="site-auth-email">Correu electrònic</label>
          <input id="site-auth-email" name="email" type="email" autocomplete="username" required>
          <label for="site-auth-password">Contrasenya</label>
          <input id="site-auth-password" name="password" type="password" autocomplete="current-password" required>
          <button type="submit">Iniciar sessió</button>
          <p class="site-auth-error" role="status" aria-live="polite"></p>
        </form>
      </div>
    `;
    document.body.append(gate);

    const form = gate.querySelector("form");
    const submit = form.querySelector("button");
    const errorMessage = gate.querySelector(".site-auth-error");
    const signOut = document.createElement("button");
    signOut.className = "site-auth-sign-out";
    signOut.type = "button";
    signOut.textContent = "Tanca la sessió";
    signOut.hidden = true;
    document.body.append(signOut);

    function requireSignIn(message = "") {
      document.documentElement.classList.remove("auth-pending");
      gate.hidden = false;
      signOut.hidden = true;
      errorMessage.textContent = message;
    }

    function allowAccess() {
      document.documentElement.classList.remove("auth-pending");
      gate.hidden = true;
      signOut.hidden = false;
    }

    if (!window.supabase?.createClient) {
      requireSignIn("No s'ha pogut carregar el servei d'autenticació. Recarrega la pàgina.");
      submit.disabled = true;
      return;
    }

    const client = window.supabase.createClient(supabaseUrl, supabaseKey, {
      auth: { storage: window.localStorage, persistSession: true, autoRefreshToken: true }
    });

    form.addEventListener("submit", async event => {
      event.preventDefault();
      submit.disabled = true;
      errorMessage.textContent = "";
      try {
        const { error } = await client.auth.signInWithPassword({
          email: form.elements.email.value.trim(),
          password: form.elements.password.value
        });
        if (error) throw error;
      } catch (error) {
        console.error("No s'ha pogut iniciar la sessió.", error);
        errorMessage.textContent = "No s'ha pogut iniciar la sessió. Comprova el correu i la contrasenya.";
      } finally {
        submit.disabled = false;
      }
    });

    signOut.addEventListener("click", async () => {
      signOut.disabled = true;
      const { error } = await client.auth.signOut();
      if (error) console.error("No s'ha pogut tancar la sessió.", error);
      signOut.disabled = false;
    });

    client.auth.onAuthStateChange((_event, session) => {
      if (session) allowAccess();
      else requireSignIn();
    });

    client.auth.getSession().then(({ data, error }) => {
      if (error) throw error;
      if (data.session) allowAccess();
      else requireSignIn();
    }).catch(error => {
      console.error("No s'ha pogut comprovar la sessió.", error);
      requireSignIn("No s'ha pogut comprovar la sessió. Torna a iniciar-la.");
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initializeAuth, { once: true });
  } else {
    initializeAuth();
  }
})();