(function() {
  var script = document.currentScript;
  var subdomain = script.getAttribute('data-subdomain');
  var color = script.getAttribute('data-color') || '#1c1917';
  var position = script.getAttribute('data-position') || 'bottom-right';
  var label = script.getAttribute('data-label') || 'Feedback';

  if (!subdomain) return;

  var host = script.src.replace(/\/feedback\/widget\.js.*$/, '');

  injectStyles();
  renderTrigger();

  function injectStyles() {
    var style = document.createElement('style');
    style.textContent = [
      '.fm-fb-trigger{position:fixed;z-index:999998;' + (position === 'bottom-left' ? 'left:20px;' : 'right:20px;') + 'bottom:20px;padding:10px 20px;border:none;border-radius:12px;background:' + color + ';color:#fff;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;font-size:14px;font-weight:600;cursor:pointer;box-shadow:0 4px 20px rgba(0,0,0,.15);transition:transform .2s}',
      '.fm-fb-trigger:hover{transform:scale(1.05)}',
      '.fm-fb-popup{position:fixed;z-index:999999;' + (position === 'bottom-left' ? 'left:20px;' : 'right:20px;') + 'bottom:80px;width:380px;max-width:calc(100vw - 40px);background:#fff;border-radius:16px;box-shadow:0 20px 60px rgba(0,0,0,.15);font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;animation:fm-fb-slide .3s ease;display:none}',
      '.fm-fb-popup.open{display:block}',
      '.fm-fb-header{padding:20px 20px 0;display:flex;justify-content:space-between;align-items:center}',
      '.fm-fb-header h3{font-size:16px;font-weight:700;color:#1c1917;margin:0}',
      '.fm-fb-close{background:none;border:none;font-size:20px;color:#a8a29e;cursor:pointer;padding:0}',
      '.fm-fb-body{padding:20px}',
      '.fm-fb-input,.fm-fb-textarea{width:100%;border:2px solid #e7e5e4;border-radius:10px;padding:10px 12px;font-size:13px;font-family:inherit;outline:none;box-sizing:border-box;margin-bottom:12px}',
      '.fm-fb-input:focus,.fm-fb-textarea:focus{border-color:' + color + '}',
      '.fm-fb-textarea{min-height:80px;resize:vertical}',
      '.fm-fb-submit{width:100%;padding:10px;border:none;border-radius:10px;background:' + color + ';color:#fff;font-size:14px;font-weight:600;cursor:pointer}',
      '.fm-fb-submit:hover{opacity:.9}',
      '.fm-fb-thanks{text-align:center;padding:30px 20px}',
      '.fm-fb-thanks p{font-size:15px;font-weight:600;color:#1c1917}',
      '.fm-fb-link{display:block;text-align:center;padding:0 20px 16px;font-size:12px;color:#a8a29e;text-decoration:none}',
      '@keyframes fm-fb-slide{from{transform:translateY(10px);opacity:0}to{transform:translateY(0);opacity:1}}'
    ].join('\n');
    document.head.appendChild(style);
  }

  function renderTrigger() {
    var trigger = document.createElement('button');
    trigger.className = 'fm-fb-trigger';
    trigger.textContent = label;

    var popup = document.createElement('div');
    popup.className = 'fm-fb-popup';
    popup.innerHTML = '<div class="fm-fb-header"><h3>Send Feedback</h3><button class="fm-fb-close">&times;</button></div>' +
      '<div class="fm-fb-body">' +
        '<input class="fm-fb-input" id="fm-fb-email" type="email" placeholder="Your email (optional)">' +
        '<textarea class="fm-fb-textarea" id="fm-fb-text" placeholder="Tell us what you think..." required></textarea>' +
        '<button class="fm-fb-submit" id="fm-fb-send">Send Feedback</button>' +
      '</div>' +
      '<div class="fm-fb-thanks" id="fm-fb-thanks" style="display:none"><p>Thanks for your feedback!</p></div>' +
      '<a class="fm-fb-link" href="' + host + '/portal/' + subdomain + '" target="_blank">View all requests &rarr;</a>';

    document.body.appendChild(trigger);
    document.body.appendChild(popup);

    trigger.addEventListener('click', function() {
      popup.classList.toggle('open');
    });

    popup.querySelector('.fm-fb-close').addEventListener('click', function() {
      popup.classList.remove('open');
    });

    document.getElementById('fm-fb-send').addEventListener('click', function() {
      var text = document.getElementById('fm-fb-text').value;
      var email = document.getElementById('fm-fb-email').value;
      if (!text.trim()) return;

      var data = new FormData();
      data.append('feature_request[title]', text.split(/[.!?\n]/).filter(Boolean)[0] || text.substring(0, 100));
      data.append('feature_request[description]', text);
      data.append('feature_request[author_email]', email || 'widget@anonymous.fm');
      data.append('feature_request[author_name]', email ? email.split('@')[0] : 'Widget User');

      var xhr = new XMLHttpRequest();
      xhr.open('POST', host + '/portal/' + subdomain);
      xhr.onload = function() {
        popup.querySelector('.fm-fb-body').style.display = 'none';
        document.getElementById('fm-fb-thanks').style.display = 'block';
        setTimeout(function() { popup.classList.remove('open'); }, 3000);
      };
      xhr.onerror = function() {
        popup.querySelector('.fm-fb-body').style.display = 'none';
        document.getElementById('fm-fb-thanks').style.display = 'block';
      };
      xhr.send(data);
    });
  }
})();
