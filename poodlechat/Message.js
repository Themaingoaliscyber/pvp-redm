Vue.component('message', {
  template: '#message_template',
  data() {
    return {};
  },
  computed: {
    textEscaped() {
      const args = this.getSafeArgs();
      const isDefaultTemplate = !this.template && this.templateId === CONFIG.defaultTemplateId;

      if (isDefaultTemplate && args.length >= 2) {
        return this.renderDefaultChatMessage(args);
      }

      let template = this.template ? this.template : this.templates[this.templateId];
      if (!template) {
        template = '{0}';
      }

      if (isDefaultTemplate && args.length === 1) {
        template = this.templates[CONFIG.defaultAltTemplateId] || '{0}';
      }

      template = template.replace(/{(\d+)}/g, (match, number) => {
        const index = Number(number);
        const arg = args[index] !== undefined ? args[index] : 'User';

        if (index === 0 && (this.color || this.badge)) {
          return this.renderAuthor(arg);
        }

        return this.escape(arg);
      });

      return this.colorize(template);
    },
  },
  methods: {
    getSafeArgs() {
      const args = Array.isArray(this.args) ? this.args.slice() : [];
      if (args.length === 0) {
        args.push('User');
      }
      if (args[0] === undefined || args[0] === null || String(args[0]).trim() === '') {
        args[0] = 'User';
      }
      return args;
    },
    renderDefaultChatMessage(args) {
      const authorRaw = args[0] !== undefined ? args[0] : 'User';
      const messageRaw = args[1] !== undefined ? args[1] : '';
      const authorHtml = (this.color || this.badge)
        ? this.renderAuthor(authorRaw)
        : `<span class="chat-author-name">${this.escape(authorRaw)}</span>`;
      const messageHtml = `<span class="chat-message-body">${this.colorize(this.escape(messageRaw))}</span>`;

      return `${authorHtml}<span class="chat-message-separator">:</span> ${messageHtml}`;
    },
    renderAuthor(author) {
      try {
        const parsedAuthor = this.parseAuthor(author);
        if (!parsedAuthor) {
          return this.renderAuthorFallback(author);
        }

        const prefixParts = [];
        if (parsedAuthor.channel) {
          prefixParts.push(`<span class="chat-prefix chat-prefix-channel">${this.escape(parsedAuthor.channel)}</span>`);
        }
        parsedAuthor.extraTags.forEach((tag) => {
          prefixParts.push(`<span class="chat-prefix chat-prefix-extra">${this.escape(tag)}</span>`);
        });
        if (parsedAuthor.playerId) {
          prefixParts.push(`<span class="chat-id-badge">${this.escape(parsedAuthor.playerId)}</span>`);
        }

        const prefixHtml = prefixParts.length > 0
          ? `<span class="chat-prefix-group">${prefixParts.join('')}</span>`
          : '';
        const roleHtml = parsedAuthor.role
          ? `<span class="chat-role-badge" style="${this.getBadgeStyle(parsedAuthor.role)}">${this.escape(parsedAuthor.role)}</span>`
          : '';
        const extraBadgesHtml = this.renderExtraBadges();

        return `<span class="chat-author-wrap">${prefixHtml}${roleHtml}${extraBadgesHtml}<span class="chat-author-name"${this.getAuthorNameStyle()}>${this.escape(parsedAuthor.name)}</span></span>`;
      } catch (error) {
        return this.renderAuthorFallback(author);
      }
    },
    renderAuthorFallback(author) {
      const safeAuthor = this.stripAuthorControlCodes(author);
      return `<span class="chat-author-wrap"><span class="chat-author-name"${this.getAuthorNameStyle()}>${this.escape(safeAuthor)}</span></span>`;
    },
    parseAuthor(author) {
      const safeAuthor = this.stripAuthorControlCodes(author).trim();
      if (!safeAuthor) {
        return null;
      }

      const extracted = this.extractPrefixTokens(safeAuthor);
      const classification = this.classifyPrefixTokens(extracted.tokens);
      const roleAndName = this.extractRoleAndName(extracted.rest);

      if (!roleAndName) {
        return {
          channel: classification.channel,
          playerId: classification.playerId,
          extraTags: classification.extraTags,
          role: null,
          name: extracted.rest || safeAuthor,
        };
      }

      return {
        channel: classification.channel,
        playerId: classification.playerId,
        extraTags: classification.extraTags,
        role: roleAndName.role,
        name: roleAndName.name,
      };
    },
    extractPrefixTokens(author) {
      const tokens = [];
      let rest = author;
      let match = rest.match(/^\[([^\]]+)\]\s*/);

      while (match) {
        tokens.push((match[1] || '').trim());
        rest = rest.slice(match[0].length).trim();
        match = rest.match(/^\[([^\]]+)\]\s*/);
      }

      return { tokens, rest: rest.trim() };
    },
    classifyPrefixTokens(tokens) {
      const channelKeywords = ['local', 'global', 'staff', 'whisper', 'discord'];
      const extraTags = [];
      let channel = null;
      let playerId = null;

      tokens.forEach((token) => {
        const safeToken = String(token || '').trim();
        if (!safeToken) {
          return;
        }

        const lower = safeToken.toLowerCase();

        if (!playerId && /^\d+$/.test(safeToken)) {
          playerId = safeToken;
          return;
        }

        if (!channel && (channelKeywords.indexOf(lower) !== -1 || lower.indexOf('whisper') === 0)) {
          channel = safeToken;
          return;
        }

        extraTags.push(safeToken);
      });

      return { channel, playerId, extraTags };
    },
    extractRoleAndName(authorWithoutPrefixes) {
      const safeAuthor = String(authorWithoutPrefixes || '').trim();
      if (!safeAuthor) {
        return null;
      }

      const separators = [
        ' • ',
        ' · ',
        ' ↯ ',
        ' | ',
        ' - ',
        ' » ',
        ' › ',
        ' ~ ',
        ' â€¢ ',
        ' Ã¢â‚¬Â¢ ',
      ];

      for (let i = 0; i < separators.length; i += 1) {
        const separator = separators[i];
        const separatorIndex = safeAuthor.indexOf(separator);

        if (separatorIndex > 0 && separatorIndex < safeAuthor.length - separator.length) {
          const role = safeAuthor.slice(0, separatorIndex).trim();
          const name = safeAuthor.slice(separatorIndex + separator.length).trim();

          if (role && name) {
            return { role, name };
          }
        }
      }

      const genericMatch = safeAuthor.match(/^(.+?)\s+(?:•|·|↯|\||»|›|~|-)\s+(.+)$/);
      if (genericMatch && genericMatch[1] && genericMatch[2]) {
        return {
          role: genericMatch[1].trim(),
          name: genericMatch[2].trim(),
        };
      }

      return null;
    },
    getAuthorNameStyle() {
      return '';
    },
    stripAuthorControlCodes(value) {
      return String(value || '')
        .replace(/\^([0-9])/g, '')
        .replace(/\^(\_|\*|\=|\~|\/|r)/g, '');
    },
    getBadgeStyle(role) {
      const badgeConfig = this.badge && typeof this.badge === 'object' ? this.badge : null;
      const baseColor = Array.isArray(this.color) && this.color.length === 3
        ? this.color
        : [255, 255, 255];
      const roleKey = String(role || '').toLowerCase();
      let background = `rgb(${baseColor[0]}, ${baseColor[1]}, ${baseColor[2]})`;
      let foreground = this.getContrastColor(baseColor);

      if (badgeConfig && typeof badgeConfig.background === 'string' && badgeConfig.background.trim() !== '') {
        background = badgeConfig.background.trim();
      }

      if (badgeConfig && typeof badgeConfig.textColor === 'string' && badgeConfig.textColor.trim() !== '') {
        foreground = badgeConfig.textColor.trim();
      }

      if ((!badgeConfig || !badgeConfig.background) && (roleKey === 'newbie' || roleKey === 'guest')) {
        background = 'rgba(22, 28, 36, 0.88)';
        foreground = '#ffffff';
      }

      return `background: ${background}; color: ${foreground}; box-shadow: 0 0.12rem 0.3rem rgba(0, 0, 0, 0.3);`;
    },
    renderExtraBadges() {
      if (!Array.isArray(this.extraBadges) || this.extraBadges.length === 0) {
        return '';
      }

      return this.extraBadges
        .map((badge) => {
          if (!badge || typeof badge !== 'object') {
            return '';
          }

          const label = this.escape(badge.label || badge.name || '');
          if (!label) {
            return '';
          }

          const style = this.getExtraBadgeStyle(badge);
          return `<span class="chat-custom-badge" style="${style}">${label}</span>`;
        })
        .join('');
    },
    getExtraBadgeStyle(badge) {
      const background = typeof badge.background === 'string' && badge.background.trim() !== ''
        ? badge.background.trim()
        : 'linear-gradient(90deg, #5a6572 0%, #39424d 100%)';
      const textColor = typeof badge.textColor === 'string' && badge.textColor.trim() !== ''
        ? badge.textColor.trim()
        : '#ffffff';

      return `background: ${background}; color: ${textColor};`;
    },
    getContrastColor(rgb) {
      const brightness = ((rgb[0] * 299) + (rgb[1] * 587) + (rgb[2] * 114)) / 1000;
      return brightness >= 160 ? '#111111' : '#ffffff';
    },
    colorize(str) {
      let s = `<span>${str.replace(/\^([0-9])/g, (match, color) => `</span><span class="color-${color}">`)}</span>`;

      const styleDict = {
        '*': 'font-weight: bold;',
        '_': 'text-decoration: underline;',
        '~': 'text-decoration: line-through;',
        '=': 'text-decoration: underline line-through;',
        'r': 'text-decoration: none;font-weight: normal;',
      };

      const styleRegex = /\^(\_|\*|\=|\~|\/|r)(.*?)(?=$|\^r|<\/em>)/;
      while (s.match(styleRegex)) {
        s = s.replace(styleRegex, (match, style, inner) => `<em style="${styleDict[style]}">${inner}</em>`);
      }
      return s.replace(/<span[^>]*><\/span[^>]*>/g, '');
    },
    escape(unsafe) {
      return String(unsafe)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
    },
  },
  props: {
    templates: {
      type: Object,
    },
    args: {
      type: Array,
    },
    template: {
      type: String,
      default: null,
    },
    templateId: {
      type: String,
      default: CONFIG.defaultTemplateId,
    },
    multiline: {
      type: Boolean,
      default: false,
    },
    color: {
      type: Array,
      default: false,
    },
    badge: {
      type: Object,
      default: null,
    },
    extraBadges: {
      type: Array,
      default: () => [],
    },
  },
});
