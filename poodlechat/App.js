window.APP = {
	template: '#app_template',
	name: 'app',
	data() {
		return {
			style: CONFIG.style,
			showInput: false,
			showWindow: false,
			showSettings: false,
			chatHiddenByUser: false,
			personalMutes: [],
			onlinePlayers: [],
			mutePlayerId: '',
			muteStatusMessage: '',
			shouldHide: true,
			backingSuggestions: [],
			removedSuggestions: [],
			templates: CONFIG.templates,
			message: '',
			messages: [],
			oldMessages: [],
			oldMessagesIndex: -1,
			tplBackups: [],
			msgTplBackups: []
		};
	},
	destroyed() {
		//clearInterval(this.focusTimer);
		if (this.listener) {
			window.removeEventListener('message', this.listener);
		}
	},
	mounted() {
		this.listener = (event) => {
			const item = event.data || event.detail; //'detail' is for debuging via browsers
			if (this[item.type]) {
				this[item.type](item);
			}
		};
		window.addEventListener('message', this.listener);
		post('https://' + GetParentResourceName() + '/loaded', JSON.stringify({}));
	},
	watch: {
		messages() {
			if (this.showWindowTimer) {
				clearTimeout(this.showWindowTimer);
			}
			this.showWindow = true;
			this.resetShowWindowTimer();

			const messagesObj = this.$refs.messages;
			this.$nextTick(() => {
				messagesObj.scrollTop = messagesObj.scrollHeight;
			});
		},
	},
	computed: {
		suggestions() {
			return this.backingSuggestions.filter((el) => this.removedSuggestions.indexOf(el.name) <= -1);
		},
	},
	methods: {
		ON_SCREEN_STATE_CHANGE({ shouldHide }) {
			this.shouldHide = shouldHide;
		},
		setChatVisibilityState({ hidden }) {
			this.chatHiddenByUser = !!hidden;
		},
		setPersonalMuteList({ mutes, onlinePlayers }) {
			this.personalMutes = Array.isArray(mutes) ? mutes : [];
			this.onlinePlayers = Array.isArray(onlinePlayers) ? onlinePlayers : [];
		},
		CLOSE_SETTINGS() {
			this.showSettings = false;
			this.updateMuteToggleState();
		},
		ON_OPEN() {
			this.showInput = true;
			this.showWindow = true;
			this.showSettings = false;
			this.closeAuxiliaryPanels();
			if (this.showWindowTimer) {
				clearTimeout(this.showWindowTimer);
			}
			this.$nextTick(() => {
				this.resetInputHeight();
				this.resize();
				setTimeout(() => this.resize(), 45);
				setTimeout(() => {
					if (this.$refs.input) {
						this.$refs.input.focus();
					}
				}, 100);
			});
			/*this.focusTimer = setInterval(() => {
				if (this.$refs.input) {
					this.$refs.input.focus();
				} else {
					clearInterval(this.focusTimer);
				}
			}, 100);*/
		},
		OPEN_SETTINGS() {
			this.showInput = true;
			this.showWindow = true;
			this.showSettings = true;
			this.message = '';
			this.clearShowWindowTimer();
			this.closeAuxiliaryPanels('settings');
			this.refreshMuteData();
			this.$nextTick(() => {
				this.resetInputHeight();
				var playerIdInput = document.getElementById('mute-player-id');
				if (playerIdInput) {
					playerIdInput.focus();
				}
			});
		},
		ON_MESSAGE({ message }) {
			this.messages.push(message);
		},
		ON_CLEAR() {
			this.messages = [];
			this.oldMessages = [];
			this.oldMessagesIndex = -1;
		},
		ON_SUGGESTION_ADD({ suggestion }) {
			const duplicateSuggestion = this.backingSuggestions.find(a => a.name == suggestion.name);
			if (duplicateSuggestion) {
				if(suggestion.help || suggestion.params) {
					duplicateSuggestion.help = suggestion.help || "";
					duplicateSuggestion.params = suggestion.params || [];
				}
				return;
			}
			if (!suggestion.params) {
				suggestion.params = []; //TODO Move somewhere else
			}
			this.backingSuggestions.push(suggestion);
		},
		ON_SUGGESTION_REMOVE({ name }) {
			if(this.removedSuggestions.indexOf(name) <= -1) {
				this.removedSuggestions.push(name);
			}
		},
		ON_TEMPLATE_ADD({ template }) {
			if (this.templates[template.id]) {
				this.warn(`Tried to add duplicate template '${template.id}'`)
			} else {
				this.templates[template.id] = template.html;
			}
		},
		ON_UPDATE_THEMES({ themes }) {
			this.removeThemes();

			this.setThemes(themes);
		},
		removeThemes() {
			for (let i = 0; i < document.styleSheets.length; i++) {
				const styleSheet = document.styleSheets[i];
				const node = styleSheet.ownerNode;

				if (node.getAttribute('data-theme')) {
					node.parentNode.removeChild(node);
				}
			}

			this.tplBackups.reverse();

			for (const [ elem, oldData ] of this.tplBackups) {
				elem.innerText = oldData;
			}

			this.tplBackups = [];

			this.msgTplBackups.reverse();

			for (const [ id, oldData ] of this.msgTplBackups) {
				this.templates[id] = oldData;
			}

			this.msgTplBackups = [];
		},
		setThemes(themes) {
			for (const [ id, data ] of Object.entries(themes)) {
				if (data.style) {
					const style = document.createElement('style');
					style.type = 'text/css';
					style.setAttribute('data-theme', id);
					style.appendChild(document.createTextNode(data.style));

					document.head.appendChild(style);
				}

				if (data.styleSheet) {
					const link = document.createElement('link');
					link.rel = 'stylesheet';
					link.type = 'text/css';
					link.href = data.baseUrl + data.styleSheet;
					link.setAttribute('data-theme', id);

					document.head.appendChild(link);
				}

				if (data.templates) {
					for (const [ tplId, tpl ] of Object.entries(data.templates)) {
						const elem = document.getElementById(tplId);

						if (elem) {
							this.tplBackups.push([ elem, elem.innerText ]);
							elem.innerText = tpl;
						}
					}
				}

				if (data.script) {
					const script = document.createElement('script');
					script.type = 'text/javascript';
					script.src = data.baseUrl + data.script;

					document.head.appendChild(script);
				}

				if (data.msgTemplates) {
					for (const [ tplId, tpl ] of Object.entries(data.msgTemplates)) {
						this.msgTplBackups.push([ tplId, this.templates[tplId] ]);
						this.templates[tplId] = tpl;
					}
				}
			}
		},
		warn(msg) {
			this.messages.push({
				args: [msg],
				template: '^3<b>CHAT-WARN</b>: ^0{0}',
			});
		},
		clearShowWindowTimer() {
			clearTimeout(this.showWindowTimer);
		},
		resetShowWindowTimer() {
			this.clearShowWindowTimer();
			this.showWindowTimer = setTimeout(() => {
				if (!this.showInput) {
					this.showWindow = false;
				}
			}, CONFIG.fadeTimeout);
		},
		keyUp() {
			this.resize();
		},
		keyDown(e) {
			if (e.which === 38 || e.which === 40) {
				e.preventDefault();
				this.moveOldMessageIndex(e.which === 38);
			} else if (e.which == 33) {
				var buf = document.getElementsByClassName('chat-messages')[0];
				buf.scrollTop = buf.scrollTop - 100;
			} else if (e.which == 34) {
				var buf = document.getElementsByClassName('chat-messages')[0];
				buf.scrollTop = buf.scrollTop + 100;
			} else if (e.which == 9) {
				e.preventDefault();
				post('https://' + GetParentResourceName() + '/cycleChannel', '{}');
			}
		},
		moveOldMessageIndex(up) {
			if (up && this.oldMessages.length > this.oldMessagesIndex + 1) {
				this.oldMessagesIndex += 1;
				this.message = this.oldMessages[this.oldMessagesIndex];
			} else if (!up && this.oldMessagesIndex - 1 >= 0) {
				this.oldMessagesIndex -= 1;
				this.message = this.oldMessages[this.oldMessagesIndex];
			} else if (!up && this.oldMessagesIndex - 1 === -1) {
				this.oldMessagesIndex = -1;
				this.message = '';
			}
		},
		resize() {
			const input = this.$refs.input;
			if (!input) {
				return;
			}
			input.style.height = '2rem';
			input.style.height = `${Math.max(input.scrollHeight + 2, 32)}px`;
		},
		resetInputHeight() {
			const input = this.$refs.input;
			if (!input) {
				return;
			}
			input.style.height = '2rem';
		},
		send(e) {
			if(this.message !== '') {
				post('https://' + GetParentResourceName() + '/chatResult', JSON.stringify({
					message: this.message,
				}));
				this.oldMessages.unshift(this.message);
				this.oldMessagesIndex = -1;
				this.hideInput();
			} else {
				this.hideInput(true);
			}
		},
		updateMuteToggleState() {
			var muteToggle = document.getElementById('mute-toggle');
			if (muteToggle) {
				muteToggle.className = this.showSettings ? 'tab active-tab' : 'tab';
			}
		},
		closeAuxiliaryPanels(except) {
			var emojiWindow = document.getElementById('emoji-window');
			var badgeWindow = document.getElementById('badge-window');
			var emojiToggle = document.getElementById('emoji-toggle');
			var badgeToggle = document.getElementById('badge-toggle');
			if (except !== 'emoji' && emojiWindow) {
				emojiWindow.style.display = 'none';
				if (emojiToggle) { emojiToggle.className = 'tab'; }
			}
			if (except !== 'badge' && badgeWindow) {
				badgeWindow.style.display = 'none';
				if (badgeToggle) { badgeToggle.className = 'tab'; }
			}
			if (except !== 'settings') {
				this.showSettings = false;
			}
			this.updateMuteToggleState();
		},
		toggleSettingsPanel() {
			this.showSettings = !this.showSettings;
			if (this.showSettings) {
				this.closeAuxiliaryPanels('settings');
				this.refreshMuteData();
				this.$nextTick(() => {
					var playerIdInput = document.getElementById('mute-player-id');
					if (playerIdInput) { playerIdInput.focus(); }
				});
			} else {
				this.updateMuteToggleState();
			}
		},
		refreshMuteData() {
			postJson('requestPersonalMuteData', {});
		},
		toggleChatVisibility() {
			var nextHidden = !this.chatHiddenByUser;
			this.chatHiddenByUser = nextHidden;
			this.muteStatusMessage = nextHidden ? 'Chat hidden.' : 'Chat visible.';
			postJson('setChatVisibility', { hidden: nextHidden }).then((resp) => {
				if (resp && Object.prototype.hasOwnProperty.call(resp, 'hidden')) {
					this.chatHiddenByUser = !!resp.hidden;
				}
			});
		},
		muteOnlinePlayer(player) {
			if (!player) { return; }
			if (player.muted) {
				this.unmutePlayer(player);
				return;
			}
			if (!player.id) {
				this.muteStatusMessage = 'Player ID unavailable.';
				return;
			}
			this.muteStatusMessage = 'Mute saved.';
			postJson('addPersonalMute', { targetId: String(player.id) }).then(() => {
				setTimeout(() => this.refreshMuteData(), 250);
			});
		},
		mutePlayerById() {
			var targetId = String(this.mutePlayerId || '').trim();
			if (!targetId) {
				this.muteStatusMessage = 'Enter a player ID.';
				return;
			}
			this.mutePlayerId = '';
			this.muteStatusMessage = 'Mute saved.';
			postJson('addPersonalMute', { targetId: targetId }).then(() => {
				setTimeout(() => this.refreshMuteData(), 250);
			});
		},
		unmutePlayer(player) {
			if (!player || !player.identifier) {
				this.muteStatusMessage = 'Mute not found.';
				return;
			}
			this.muteStatusMessage = 'Player unmuted.';
			postJson('removePersonalMute', { identifier: player.identifier }).then(() => {
				setTimeout(() => this.refreshMuteData(), 250);
			});
		},
		hideInput(canceled = false) {
			if (canceled) {
				post('https://' + GetParentResourceName() + '/chatResult', JSON.stringify({ canceled }));
			}
			this.message = '';
			this.showInput = false;
			this.showSettings = false;
			this.closeAuxiliaryPanels();
			this.$nextTick(() => this.resetInputHeight());
			//clearInterval(this.focusTimer);
			this.resetShowWindowTimer();
		},
		setChannel({channelId}) {
			document.querySelectorAll('.channel').forEach(e => {
				if (e.id == channelId) {
					e.className = 'channel tab active-tab';
				} else {
					e.className = 'channel tab'
				}
			});
		},
		setPermissions({permissions}) {
			var perms = JSON.parse(permissions);

			if (perms.canAccessStaffChannel) {
				document.getElementById('channel-staff').style.display = 'inline-block';
			} else {
				document.getElementById('channel-staff').style.display = 'none';
			}
		},
		setBadgeCatalog({ badges }) {
			setCustomBadgeCatalog(Array.isArray(badges) ? badges : []);
		},
		setBadgeState({ selectedId, cooldownUntil }) {
			setCustomBadgeState(selectedId || null, Number(cooldownUntil) || 0);
		},
	},
};

function postJson(endpoint, payload) {
	return fetch('https://' + GetParentResourceName() + '/' + endpoint, {
		method: 'POST',
		headers: {
			'Content-Type': 'application/json'
		},
		body: JSON.stringify(payload || {})
	}).then(resp => resp.json()).catch(function() { return {}; });
}

function colorToRgb(color) {
	return `rgb(${color[0]},${color[1]},${color[2]})`
}

var emojis = [];
var customBadges = [];
var selectedCustomBadgeId = null;
var customBadgeCooldownUntil = 0;

function escapeHtml(value) {
	return String(value || '')
		.replace(/&/g, '&amp;')
		.replace(/</g, '&lt;')
		.replace(/>/g, '&gt;')
		.replace(/"/g, '&quot;')
		.replace(/'/g, '&#039;');
}

function getCustomBadgeStyle(badge) {
	const background = badge && typeof badge.background === 'string' && badge.background.trim() !== ''
		? badge.background.trim()
		: 'linear-gradient(90deg, #5a6572 0%, #39424d 100%)';
	const textColor = badge && typeof badge.textColor === 'string' && badge.textColor.trim() !== ''
		? badge.textColor.trim()
		: '#ffffff';

	return `background: ${background}; color: ${textColor};`;
}

function isCustomBadgeCoolingDown() {
	return customBadgeCooldownUntil > Math.floor(Date.now() / 1000);
}

function setCustomBadgeCatalog(badges) {
	customBadges = Array.isArray(badges) ? badges : [];
	renderCustomBadgeList();
}

function setCustomBadgeState(selectedId, cooldownUntil) {
	selectedCustomBadgeId = selectedId || null;
	customBadgeCooldownUntil = Number(cooldownUntil) || 0;
	renderCustomBadgeList();
}

function applyBadgeDataResponse(resp) {
	resp = resp || {};
	try {
		setCustomBadgeCatalog(JSON.parse(resp.customBadges || '[]'));
	} catch (e) {
		setCustomBadgeCatalog([]);
	}
	setCustomBadgeState(resp.selectedBadgeId || null, resp.badgeCooldownUntil || 0);
}

function requestBadgeData() {
	return fetch('https://' + GetParentResourceName() + '/requestBadgeData', {
		method: 'POST',
		headers: {
			'Content-Type': 'application/json'
		},
		body: JSON.stringify({})
	}).then(resp => resp.json()).then(applyBadgeDataResponse).catch(function() {});
}

function renderCustomBadgeList() {
	var badgeList = document.getElementById('badge-list');
	if (!badgeList) {
		return;
	}

	badgeList.innerHTML = '';

	if (!Array.isArray(customBadges) || customBadges.length === 0) {
		var empty = document.createElement('div');
		empty.className = 'help';
		empty.textContent = 'No badges configured.';
		badgeList.appendChild(empty);
		return;
	}

	var coolingDown = isCustomBadgeCoolingDown();

	customBadges.forEach(function(badge) {
		var badgeId = badge.id || '';
		var isSelected = selectedCustomBadgeId && badgeId === selectedCustomBadgeId;
		var isDisabled = coolingDown && selectedCustomBadgeId && !isSelected;

		var button = document.createElement('button');
		button.type = 'button';
		button.className = 'badge-option';
		if (isSelected) {
			button.classList.add('selected');
		}
		if (isDisabled) {
			button.classList.add('disabled');
		}

		if (isDisabled) {
			var secondsLeft = Math.max(0, customBadgeCooldownUntil - Math.floor(Date.now() / 1000));
			var minutesLeft = Math.ceil(secondsLeft / 60);
			button.title = `You can change badge in ${minutesLeft} minute(s).`;
		}

		var chip = document.createElement('span');
		chip.className = 'badge-chip';
		chip.style.cssText = getCustomBadgeStyle(badge);
		chip.innerHTML = escapeHtml(badge.label || badge.name || badgeId);
		button.appendChild(chip);

		button.addEventListener('click', function() {
			if (!badgeId || isDisabled) {
				return;
			}

			fetch('https://' + GetParentResourceName() + '/setBadge', {
				method: 'POST',
				headers: {
					'Content-Type': 'application/json'
				},
				body: JSON.stringify({
					badgeId: badgeId
				})
			});

			var input = document.querySelector('textarea');
			if (input) {
				input.focus();
			}
		});

		badgeList.appendChild(button);
	});
}

function populateEmojiList(filter) {
	var emojiList = document.getElementById('emoji-list');

	emojiList.innerHTML = '';

	emojis.forEach(emoji => {
		var addToList = false;

		for (var i = 0; i < emoji[0].length; ++i) {
			if (!filter || filter == '' || emoji[0][i].toLowerCase().includes(filter.toLowerCase())) {
				addToList = true;
				break;
			}
		}

		if (addToList) {
			var div = document.createElement('div');
			div.className = 'emoji';
			div.innerHTML = emoji[1];
			div.addEventListener('click', function(event) {
				var input = document.querySelector('textarea');
				input.value = input.value + this.innerHTML;
				var evt = new Event('input');
				input.dispatchEvent(evt);
				input.focus();
			});
			div.addEventListener('mouseover', function(event) {
				document.getElementById('emoji-search').placeholder = emoji[0].join(', ');
			});
			div.addEventListener('mouseout', function(event) {
				document.getElementById('emoji-search').placeholder = 'Search...';
			});
			emojiList.appendChild(div);
		}
	});
}

window.addEventListener('load', event => {
	fetch('https://' + GetParentResourceName() + '/onLoad').then(resp => resp.json()).then(resp => {
		document.getElementById('channel-local').style.color = colorToRgb(resp.localColor);
		document.getElementById('channel-global').style.color = colorToRgb(resp.globalColor);
		document.getElementById('channel-staff').style.color = colorToRgb(resp.staffColor);

		emojis = JSON.parse(resp.emoji);
		populateEmojiList();

		applyBadgeDataResponse(resp);
		if (Object.prototype.hasOwnProperty.call(resp, 'chatHidden')) {
			window.dispatchEvent(new CustomEvent('message', {
				detail: { type: 'setChatVisibilityState', hidden: resp.chatHidden },
			}));
		}
		requestBadgeData();
		setTimeout(requestBadgeData, 750);
		setTimeout(requestBadgeData, 2000);
	});

	document.querySelectorAll('.channel').forEach(e => e.addEventListener('click', function(event) {
		fetch('https://' + GetParentResourceName() + '/setChannel', {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json'
			},
			body: JSON.stringify({
				channelId: this.id
			})
		});
	}));

	document.querySelectorAll('.tab').forEach(e => e.addEventListener('click', function(event) {
		document.querySelector('textarea').focus();
	}));

	document.getElementById('emoji-toggle').addEventListener('click', function(event) {
		window.dispatchEvent(new CustomEvent('message', {
			detail: { type: 'CLOSE_SETTINGS' },
		}));
		var emojiWindow = document.getElementById('emoji-window');
		var badgeWindow = document.getElementById('badge-window');
		var badgeToggle = document.getElementById('badge-toggle');

		if (emojiWindow.style.display == 'flex') {
			emojiWindow.style.display = 'none';
			this.className = 'tab';
		} else {
			emojiWindow.style.display = 'flex';
			if (badgeWindow) {
				badgeWindow.style.display = 'none';
			}
			if (badgeToggle) {
				badgeToggle.className = 'tab';
			}
			this.className = 'tab active-tab';
		}
		document.querySelector('textarea').focus();
	});

	document.getElementById('badge-toggle').addEventListener('click', function(event) {
		window.dispatchEvent(new CustomEvent('message', {
			detail: { type: 'CLOSE_SETTINGS' },
		}));
		var badgeWindow = document.getElementById('badge-window');
		var emojiWindow = document.getElementById('emoji-window');
		var emojiToggle = document.getElementById('emoji-toggle');

		if (badgeWindow.style.display == 'flex') {
			badgeWindow.style.display = 'none';
			this.className = 'tab';
		} else {
			badgeWindow.style.display = 'flex';
			if (emojiWindow) {
				emojiWindow.style.display = 'none';
			}
			if (emojiToggle) {
				emojiToggle.className = 'tab';
			}
			this.className = 'tab active-tab';
			if (!Array.isArray(customBadges) || customBadges.length === 0) {
				requestBadgeData();
			}
			renderCustomBadgeList();
		}
		document.querySelector('textarea').focus();
	});

	document.getElementById('emoji-search').addEventListener('input', function(event) {
		populateEmojiList(this.value);
	});

	document.querySelectorAll('.no-focus').forEach(e => e.addEventListener('focus', event => {
		event.preventDefault();

		if (event.relatedTarget) {
			event.relatedTarget.focus();
		} else {
			event.currentTarget.blur();
		}
	}));
});
