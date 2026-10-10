import 'dart:async';

import 'package:flutter/material.dart';

import '../services/chat_service.dart';
import '../services/user_service.dart';
import 'chat_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();

  String _currentUserId = '';
  String _currentUserEmail = '';
  String _searchText = '';
  String? _identityError;
  bool _loadingIdentity = true;
  StreamSubscription<dynamic>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    _loadCurrentUser();
  }

  void _handleSearchChanged() {
    final value = _searchController.text.trim().toLowerCase();
    if (value != _searchText) setState(() => _searchText = value);
  }

  void _loadCurrentUser() {
    try {
      // Firebase is the live identity; shared preferences can belong to another tab.
      _authSubscription = UserService().authStateChanges.listen((firebaseUser) {
        if (!mounted) return;
        setState(() {
          _currentUserId = firebaseUser?.uid ?? '';
          _currentUserEmail = firebaseUser?.email?.trim().toLowerCase() ?? '';
          _identityError = firebaseUser == null
              ? 'Sign in with a Firebase account to use chat.'
              : null;
          _loadingIdentity = false;
        });
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _identityError = error is StateError
            ? error.message
            : 'Unable to load your Firebase account.';
        _loadingIdentity = false;
      });
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Column(
            children: [
              SearchBar(
                key: const Key('chatSearchBar'),
                controller: _searchController,
                hintText: 'Search by name or email',
                leading: const Icon(Icons.search),
                trailing: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      tooltip: 'Clear search',
                      onPressed: _searchController.clear,
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(child: _buildUserList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserList() {
    if (_loadingIdentity) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (_identityError != null) {
      return _ChatEmptyState(
        icon: Icons.lock_outline,
        title: 'Firebase account required',
        message: _identityError!,
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _chatService.getUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _ChatEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Unable to load users',
            message: 'Check your connection and Cloud Firestore rules.',
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        final users =
            (snapshot.data ?? const <Map<String, dynamic>>[]).where((user) {
              final uid = user['uid']?.toString() ?? '';
              final email = user['email']?.toString().trim() ?? '';
              if (uid == _currentUserId ||
                  (_currentUserEmail.isNotEmpty &&
                      email.toLowerCase() == _currentUserEmail)) {
                return false;
              }
              if (_searchText.isEmpty) return true;
              final searchable = [
                _displayName(user),
                user['username']?.toString() ?? '',
                email,
              ].join(' ').toLowerCase();
              return searchable.contains(_searchText);
            }).toList()..sort(
              (first, second) => _displayName(
                first,
              ).toLowerCase().compareTo(_displayName(second).toLowerCase()),
            );

        if (users.isEmpty) {
          return _ChatEmptyState(
            icon: _searchText.isEmpty
                ? Icons.people_outline
                : Icons.person_search_outlined,
            title: _searchText.isEmpty
                ? 'No other users yet'
                : 'No users found',
            message: _searchText.isEmpty
                ? 'Registered Firebase users will appear here.'
                : 'Try searching with another name or email.',
          );
        }

        return ListView.separated(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemCount: users.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final user = users[index];
            final uid = user['uid']?.toString() ?? '';
            final email = user['email']?.toString() ?? '';
            final name = _displayName(user);
            return Card(
              clipBehavior: Clip.antiAlias,
              elevation: 0,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                leading: CircleAvatar(
                  child: Text(
                    name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  email.isEmpty ? 'No email' : email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: uid.isEmpty
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ChatDetailScreen(
                            receiverId: uid,
                            receiverEmail: email,
                            receiverName: name,
                          ),
                        ),
                      ),
              ),
            );
          },
        );
      },
    );
  }

  String _displayName(Map<String, dynamic> user) {
    final fullName = [
      user['firstName']?.toString() ?? '',
      user['lastName']?.toString() ?? '',
    ].where((part) => part.trim().isNotEmpty).join(' ').trim();
    if (fullName.isNotEmpty) return fullName;
    final username = user['username']?.toString().trim() ?? '';
    if (username.isNotEmpty) return username;
    final email = user['email']?.toString() ?? '';
    return email.isEmpty ? 'Unknown user' : email.split('@').first;
  }
}

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: colors.primary),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
