(function() {
  var script = document.currentScript;
  var token = script.getAttribute('data-token');
  var color = script.getAttribute('data-color') || '#1c1917';
  var position = script.getAttribute('data-position') || 'bottom-right';

  if (!token) return;

  var storageKey = 'fm_nps_' + token;
  if (localStorage.getItem(storageKey)) return;

  var host = script.src.replace(/\/nps\/widget\.js.*$/, '');

  setTimeout(function() { init(); }, 3000);

  function init() {
    injectStyles();
    fetchConfig(function(config) {
      renderWidget(config);
    });
  }

  function injectStyles() {
    var style = document.createElement('style');
    style.textContent = [
      '.fm-nps-widget{position:fixed;z-index:999999;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;' + (position === 'bottom-left' ? 'left:20px;' : 'right:20px;') + 'bottom:20px;width:380px;max-width:calc(100vw - 40px);animation:fm-slide-up .3s ease}',
      '.fm-nps-card{background:#fff;border-radius:16px;box-shadow:0 20px 60px rgba(0,0,0,.15);padding:24px;position:relative}',
      '.fm-nps-close{position:absolute;top:12px;right:12px;background:none;border:none;cursor:pointer;color:#a8a29e;font-size:18px;line-height:1;padding:4px}',
      '.fm-nps-close:hover{color:#1c1917}',
      '.fm-nps-q{font-size:15px;font-weight:600;color:#1c1917;margin:0 0 16px;line-height:1.4}',
      '.fm-nps-scores{display:flex;gap:4px;margin-bottom:8px}',
      '.fm-nps-score{width:100%;height:36px;border:2px solid #e7e5e4;border-radius:8px;background:#fff;cursor:pointer;font-size:13px;font-weight:600;color:#57534e;transition:all .15s}',
      '.fm-nps-score:hover{border-color:' + color + ';color:' + color + '}',
      '.fm-nps-score.active{background:' + color + ';border-color:' + color + ';color:#fff}',
      '.fm-nps-labels{display:flex;justify-content:space-between;font-size:11px;color:#a8a29e;margin-bottom:16px}',
      '.fm-nps-followup{display:none}',
      '.fm-nps-followup.show{display:block}',
      '.fm-nps-textarea{width:100%;border:2px solid #e7e5e4;border-radius:10px;padding:10px 12px;font-size:13px;resize:vertical;min-height:60px;outline:none;font-family:inherit;box-sizing:border-box}',
      '.fm-nps-textarea:focus{border-color:' + color + '}',
      '.fm-nps-submit{width:100%;margin-top:12px;padding:10px;border:none;border-radius:10px;background:' + color + ';color:#fff;font-size:14px;font-weight:600;cursor:pointer}',
      '.fm-nps-submit:hover{opacity:.9}',
      '.fm-nps-thanks{text-align:center;padding:20px 0}',
      '.fm-nps-thanks p{font-size:15px;font-weight:600;color:#1c1917}',
      '@keyframes fm-slide-up{from{transform:translateY(20px);opacity:0}to{transform:translateY(0);opacity:1}}'
    ].join('\n');
    document.head.appendChild(style);
  }

  function fetchConfig(cb) {
    var xhr = new XMLHttpRequest();
    xhr.open('GET', host + '/api/v1/nps/config?token=' + token);
    xhr.onload = function() {
      if (xhr.status === 200) cb(JSON.parse(xhr.responseText));
    };
    xhr.send();
  }

  function renderWidget(config) {
    var widget = document.createElement('div');
    widget.className = 'fm-nps-widget';
    widget.innerHTML = '<div class="fm-nps-card">' +
      '<button class="fm-nps-close" id="fm-nps-close">&times;</button>' +
      '<p class="fm-nps-q">' + escapeHtml(config.question) + '</p>' +
      '<div class="fm-nps-scores" id="fm-nps-scores"></div>' +
      '<div class="fm-nps-labels"><span>Not likely</span><span>Very likely</span></div>' +
      '<div class="fm-nps-followup" id="fm-nps-followup">' +
        '<p style="font-size:13px;color:#57534e;margin:0 0 8px">' + escapeHtml(config.followup_question) + '</p>' +
        '<textarea class="fm-nps-textarea" id="fm-nps-comment" placeholder="Tell us more..."></textarea>' +
        '<button class="fm-nps-submit" id="fm-nps-submit">Submit</button>' +
      '</div>' +
      '<div class="fm-nps-thanks" id="fm-nps-thanks" style="display:none"><p>' + escapeHtml(config.thank_you_message) + '</p></div>' +
    '</div>';

    document.body.appendChild(widget);

    var scoresEl = document.getElementById('fm-nps-scores');
    var selectedScore = null;

    for (var i = 0; i <= 10; i++) {
      var btn = document.createElement('button');
      btn.className = 'fm-nps-score';
      btn.textContent = i;
      btn.setAttribute('data-score', i);
      btn.addEventListener('click', function() {
        selectedScore = parseInt(this.getAttribute('data-score'));
        var all = scoresEl.querySelectorAll('.fm-nps-score');
        for (var j = 0; j < all.length; j++) all[j].classList.remove('active');
        this.classList.add('active');
        document.getElementById('fm-nps-followup').classList.add('show');
      });
      scoresEl.appendChild(btn);
    }

    document.getElementById('fm-nps-close').addEventListener('click', function() {
      widget.remove();
    });

    document.getElementById('fm-nps-submit').addEventListener('click', function() {
      if (selectedScore === null) return;
      var comment = document.getElementById('fm-nps-comment').value;

      var data = new FormData();
      data.append('token', token);
      data.append('score', selectedScore);
      data.append('comment', comment);
      data.append('page_url', window.location.href);

      var xhr = new XMLHttpRequest();
      xhr.open('POST', host + '/api/v1/nps/respond');
      xhr.onload = function() {
        document.getElementById('fm-nps-followup').style.display = 'none';
        scoresEl.style.display = 'none';
        widget.querySelector('.fm-nps-q').style.display = 'none';
        widget.querySelector('.fm-nps-labels').style.display = 'none';
        document.getElementById('fm-nps-thanks').style.display = 'block';
        localStorage.setItem(storageKey, '1');
        setTimeout(function() { widget.remove(); }, 4000);
      };
      xhr.send(data);
    });
  }

  function escapeHtml(str) {
    var div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
  }
})();
