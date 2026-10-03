import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/ui_widgets.dart';
import 'parcours_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  final List<ChatMessage> _messages = [
    ChatMessage(welcomeMessage, false, DateTime.now()),
  ];

  bool _isLoading = false;

  /// Etat reel de la connexion au backend, teste a l'ouverture du chat.
  bool? _online;

  /// Parcours identifie par le moteur de classification sur le dernier echange.
  /// Sert a proposer le contenu de la base de connaissances (module 4).
  String? _parcours;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    final online = await ApiService.ping();
    if (mounted) setState(() => _online = online);
  }

  bool get _isTyping =>
      _isLoading && _messages.isNotEmpty && _messages.last.text.isEmpty;

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
      _messages.add(ChatMessage(trimmed, true, DateTime.now()));
      _messages.add(ChatMessage('', false, DateTime.now()));
    });
    _controller.clear();
    _scrollToBottom(extra: 60);

    final history = _messages
        .where((m) => m.text.isNotEmpty)
        .map<({String role, String text})>((m) =>
            (role: m.isUser ? 'user' : 'assistant', text: m.text))
        .toList();

    String reply;
    String? parcours;
    try {
      final resultat = await ApiService.sendMessage(history);
      reply = resultat.reply;
      parcours = resultat.parcours;
    } on ApiException catch (e) {
      reply = e.message;
    } catch (_) {
      reply =
          'Impossible de joindre le serveur. Vérifie que le backend est lancé '
          'et que l’URL est correcte.';
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _parcours = parcours;
      final last = _messages.last;
      if (last.text.isEmpty && !last.isUser) {
        _messages[_messages.length - 1] =
            ChatMessage(reply, false, DateTime.now());
      } else {
        _messages.add(ChatMessage(reply, false, DateTime.now()));
      }
    });
    _scrollToBottom();
  }

  /// Libelle lisible du slug renvoye par le backend.
  String? _parcoursLabel(String slug) => const {
        'grossesse': 'Grossesse',
        'corps': 'Corps',
        'protection': 'Protection',
        'aide': 'Aide',
      }[slug];

  void _scrollToBottom({double extra = 120}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + extra,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                const AyanaLogo(mark: true, height: 34),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _online == null
                          ? 'Vérification…'
                          : _online!
                              ? 'En ligne • Confidentiel 🔒'
                              : 'Hors ligne • Vérifie la connexion',
                      style: TextStyle(
                        color: _online == false
                            ? AppColors.textMuted
                            : AppColors.successText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + 1,
              itemBuilder: (context, i) {
                if (i == _messages.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (_parcours != null &&
                            _parcoursLabel(_parcours!) != null)
                          ParcoursSuggestion(
                            label: _parcoursLabel(_parcours!)!,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ParcoursScreen(
                                    slug: _parcours!),
                              ),
                            ),
                          ),
                        if (_parcours != null &&
                            _parcoursLabel(_parcours!) != null)
                          const SizedBox(height: 14),
                        const Text('Choisis ou écris ta question',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                        const SizedBox(height: 10),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: quickReplies.keys
                              .map((label) => OutlinedButton(
                                    onPressed: () => _send(label),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppColors.border),
                                      backgroundColor: AppColors.surface,
                                      foregroundColor: AppColors.textPrimary,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20)),
                                    ),
                                    child: Text(label),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  );
                }
                final m = _messages[i];
                final isTyping = m.text.isEmpty && !m.isUser && _isTyping;
                return Align(
                  alignment:
                      m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      gradient: m.isUser
                          ? brandGradient()
                          : const LinearGradient(
                              colors: [AppColors.surface, AppColors.surfaceHigh]),
                      borderRadius: BorderRadius.circular(16),
                      border: m.isUser
                          ? null
                          : Border.all(color: AppColors.border),
                    ),
                    child: isTyping
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.sage),
                              ),
                              SizedBox(width: 10),
                              Text('AYANA écrit…',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13)),
                            ],
                          )
                        : Text(
                            m.text,
                            style: TextStyle(
                              color:
                                  m.isUser ? Colors.white : AppColors.textPrimary,
                              height: 1.3,
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Écris ta question…',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    ),
                    onSubmitted: _send,
                  ),
                ),
                const SizedBox(width: 8),
                Ink(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: brandGradient(),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                    onPressed:
                        _isLoading ? null : () => _send(_controller.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}