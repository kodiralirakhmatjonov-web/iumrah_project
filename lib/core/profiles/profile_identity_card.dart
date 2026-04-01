import 'package:flutter/material.dart';

import 'package:iumrah_project/core/navigation/premium_route.dart';
import 'package:iumrah_project/core/profiles/edit_profilepage.dart';
import 'package:iumrah_project/core/profiles/profile_store.dart';

// если у тебя другое расположение edit страницы — поправь импорт

class ProfileIdentityCard extends StatelessWidget {
  const ProfileIdentityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ProfileData>(
      valueListenable: ProfileStore.notifier,
      builder: (context, profile, _) {
        /// ===== PATH FIX (без падений)
        String path;

        if (profile.avatarKey.startsWith('male_')) {
          path = 'assets/profile/avatars/male/${profile.avatarKey}.png';
        } else if (profile.avatarKey.startsWith('female_')) {
          path = 'assets/profile/avatars/female/${profile.avatarKey}.png';
        } else {
          path = 'assets/profile/avatars/male/male_01.png';
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PremiumRoute.push(const EditProfilePage()),
            );
          },

          /// ===== CARD UI
          child: Container(
            height: 100,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Row(
              children: [
                /// ===== AVATAR
                ClipOval(
                  child: Image.asset(
                    path,
                    width: 75,
                    height: 75,
                    fit: BoxFit.cover,

                    /// 💥 НЕ ДАЁТ КРАШИТЬСЯ
                    errorBuilder: (_, __, ___) {
                      return Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFE0DED6),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 14),

                /// ===== NAME + EMAIL
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name.isEmpty ? 'Your name' : profile.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4A4A54),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.email.isEmpty ? '—' : profile.email,
                        style: const TextStyle(
                            fontSize: 13,
                            color: Color.fromARGB(255, 83, 83, 83)),
                      ),
                    ],
                  ),
                ),

                /// ===== IOS ARROW
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 30,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
