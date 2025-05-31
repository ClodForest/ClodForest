// Create a copy button
const button = document.createElement('button');
button.innerText = 'Copy Chat';
button.style.position = 'fixed';
button.style.top = '10px';
button.style.right = '10px';
button.style.zIndex = '9999';
button.style.padding = '10px';
button.style.backgroundColor = '#007acc';
button.style.color = 'white';
button.style.border = 'none';
button.style.borderRadius = '5px';

button.onclick = function() {
  const chatContainer = document.querySelector('.flex-1.flex.flex-col.gap-3.px-4.max-w-3xl.mx-auto.w-full.pt-1') || document.body;
  const textarea = document.createElement('textarea');
  textarea.value = chatContainer.innerHTML;
  document.body.appendChild(textarea);
  textarea.select();
  document.execCommand('copy');
  document.body.removeChild(textarea);
  button.innerText = 'Copied!';
  setTimeout(() => button.innerText = 'Copy Chat', 1000);
};

document.body.appendChild(button);
