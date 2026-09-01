// A-Anie — minimal marketing-site JS (no framework, no analytics).
// Accessibility: prefers-reduced-motion, focus-visible, aria-live,
// carousel keyboard support, accordion <details> native behaviour.
(function(){
  const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;

  // ── IntersectionObserver: reveal on scroll ──
  const obs = new IntersectionObserver((entries)=>{
    for (const e of entries){
      if (e.isIntersecting){
        e.target.classList.add('in');
        // staggered children if they opt-in via data-stagger
        const kids = e.target.querySelectorAll('[data-stagger]');
        kids.forEach((k,i)=>setTimeout(()=>k.classList.add('in'),60*i));
        obs.unobserve(e.target);
      }
    }
  },{threshold:.15});
  document.querySelectorAll('.reveal').forEach(el=>obs.observe(el));

  // ── Hero word reveal (brand line breaks) ──
  const heroH = document.querySelector('.hero-h');
  if (heroH){
    // walk children, wrap text nodes in <span class="reveal-word"> word-by-word
    const wrapWords = (root)=>{
      const nodes = [...root.childNodes];
      for (const n of nodes){
        if (n.nodeType===3){
          const words = n.textContent.split(/(\s+)/);
          n.replaceWith(...words.map(w=>{
            if (/^\s+$/.test(w)) return document.createTextNode(w);
            const s = document.createElement('span'); s.className='reveal-word'; s.textContent=w; return s;
          }));
        } else if (n.nodeType===1){
          wrapWords(n);
        }
      }
    };
    wrapWords(heroH);
    if (!reduce){
      const wObs = new IntersectionObserver((es)=>{
        for (const e of es){
          if (e.isIntersecting){
            [...e.target.querySelectorAll('.reveal-word')].forEach((w,i)=>setTimeout(()=>w.classList.add('in'),60*i));
            wObs.unobserve(e.target);
            return;
          }
        }
      },{threshold:.4});
      wObs.observe(heroH);
    } else {
      heroH.querySelectorAll('.reveal-word').forEach(w=>w.classList.add('in'));
    }
  }

  // ── Mic button: toggles a synthetic animated waveform ──
  const micBtn = document.getElementById('micBtn');
  const waveSvg = document.querySelector('.wave-svg');
  const BAR_COUNT = 64;
  const initial = Array.from({length:BAR_COUNT},()=>2+Math.random()*8);
  let bars = [];
  function renderBars(vals){
    if (!waveSvg) return;
    if (bars.length===0){
      for (let i=0;i<vals.length;i++){
        const r = document.createElementNS('http://www.w3.org/2000/svg','rect');
        const x = (i/vals.length)*600;
        r.setAttribute('x', x.toFixed(2));
        r.setAttribute('y','0');
        r.setAttribute('width','6');
        r.setAttribute('height','80');
        r.setAttribute('transform', `translate(-3,40) scale(1,0)`);
        waveSvg.firstElementChild.appendChild(r);
        bars.push(r);
      }
    }
    bars.forEach((b,i)=>{
      b.setAttribute('transform', `translate(-3,40) scale(1,${vals[i]/40})`);
    });
  }
  renderBars(initial);
  let running = false;
  let timer = null;
  function tick(){
    const arr = Array.from({length:BAR_COUNT},()=>4+Math.random()*72);
    renderBars(arr);
    timer = setTimeout(tick, 140);
  }
  if (micBtn){
    micBtn.addEventListener('click',()=>{
      running = !running;
      micBtn.setAttribute('aria-pressed', String(running));
      if (running){
        if (reduce) return; // static bars only
        tick();
      } else {
        clearTimeout(timer);
        renderBars(initial);
      }
    });
  }

  // ── Tone chips: local toggle (visual only — wire to settings later) ──
  document.querySelectorAll('.tone-row').forEach(row=>{
    row.addEventListener('click', e=>{
      const btn = e.target.closest('.tone-chip');
      if (!btn) return;
      [...row.querySelectorAll('.tone-chip')].forEach(b=>b.removeAttribute('data-active'));
      btn.setAttribute('data-active','true');
    });
  });

  // ── Mobile carousel: keyboard arrow nav + dots ──
  const car = document.querySelector('.how-carousel');
  if (car){
    const track = car.querySelector('.how-carousel-track');
    const dotsWrap = car.querySelector('.carousel-dots');
    const slides = [...track.querySelectorAll('.how-card-m')];
    slides.forEach((_,i)=>{
      const b = document.createElement('button');
      b.setAttribute('role','tab');
      b.setAttribute('aria-label', `Go to slide ${i+1}`);
      b.addEventListener('click',()=>scrollTo(i));
      dotsWrap.appendChild(b);
    });
    function scrollTo(i){
      slides[Math.max(0,Math.min(i,slides.length-1))].scrollIntoView({behavior:reduce?'auto':'smooth',inline:'center',block:'nearest'});
    }
    dotsWrap.firstElementChild?.setAttribute('aria-selected','true');
    car.querySelectorAll('.carousel-btn').forEach(b=>{
      b.addEventListener('click',()=>{
        const cur = slides.findIndex(s=>Math.abs(s.getBoundingClientRect().left-track.getBoundingClientRect().left)<(s.offsetWidth/2));
        scrollTo((cur<0?0:cur) + Number(b.dataset.dir));
      });
    });
    track.addEventListener('scroll',()=>{
      const tRect = track.getBoundingClientRect();
      const i = slides.findIndex(s=>{
        const r = s.getBoundingClientRect();
        return Math.abs(r.left - tRect.left) < s.offsetWidth/2;
      });
      [...dotsWrap.children].forEach((d,di)=>d.setAttribute('aria-selected', String(di===i)));
    },{passive:true});
    track.addEventListener('keydown', e=>{
      if (e.key==='ArrowRight'){e.preventDefault();car.querySelector('.next').click()}
      else if (e.key==='ArrowLeft'){e.preventDefault();car.querySelector('.prev').click()}
    });
  }

  // ── Contact form: real POST to /api/v1/contact, no fake success ──
  const form = document.getElementById('contact-form');
  const status = document.getElementById('c-status');
  const submit = document.getElementById('c-submit');
  if (form && status && submit){
    function setErr(id,msg){
      const el = document.getElementById(id);
      if (!el) return;
      el.hidden = !msg;
      el.textContent = msg||'';
      if (msg){
        const input = el.previousElementSibling;
        if (input && input.focus) input.focus();
      }
    }
    function clearAll(){
      ['c-name-err','c-email-err','c-topic-err','c-msg-err'].forEach(id=>setErr(id,''));
    }
    form.addEventListener('submit', async e=>{
      e.preventDefault();
      clearAll();
      status.textContent='';
      status.className='c-status';
      const data = Object.fromEntries(new FormData(form).entries());
      const errs = [];
      if (!data.name||data.name.trim().length<2) errs.push(['c-name-err','Please enter your name.']);
      if (!data.email||!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(data.email)) errs.push(['c-email-err','Please enter a valid email.']);
      if (!data.topic) errs.push(['c-topic-err','Please choose a topic.']);
      if (!data.message||data.message.trim().length<10) errs.push(['c-msg-err','Please write at least 10 characters.']);
      if (errs.length){ errs.forEach(([id,m])=>setErr(id,m)); status.textContent='Please fix the highlighted fields.'; return; }

      submit.disabled = true;
      submit.textContent = 'Sending…';
      try {
        const res = await fetch('/api/v1/contact', {
          method:'POST',
          headers:{'Content-Type':'application/json'},
          body: JSON.stringify(data)
        });
        if (!res.ok){
          const j = await res.json().catch(()=>({}));
          throw new Error(j.message||`Server returned ${res.status}`);
        }
        const json = await res.json().catch(()=>({}));
        form.reset();
        status.className = 'c-status is-success';
        status.textContent = (json.message||'Message sent. Thanks — Sachin will reply soon.');
      } catch (err){
        status.className = 'c-status';
        status.textContent = `Couldn't send. ${err.message}. You can email sachin@a-anie.example directly.`;
      } finally {
        submit.disabled = false;
        submit.textContent = 'Send message';
      }
    });
  }

  // ── Demo steps: auto-rotate if no reduced-motion ──
  const demo = document.querySelector('.demo');
  if (demo && !reduce){
    const steps = [...demo.querySelectorAll('.demo-step')];
    let i = 0;
    const use = (idx)=>{
      steps.forEach((s,k)=>{s.style.opacity = (k===idx)?'1':'0.45'; s.style.transform = (k===idx)?'translateX(0)':'translateX(0)'});
    };
    use(0);
    setInterval(()=>{use(i=(i+1)%steps.length);}, 3200);
  }
})();
