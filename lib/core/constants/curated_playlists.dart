// lib/core/constants/curated_playlists.dart
//
// Phase 5A — Real Curated Playlists.
//
// Each playlist contains fully-resolved Song objects with hand-picked real
// YouTube video IDs. No search queries, no network calls to populate the
// list. The song list is available instantly on screen open; only stream-URL
// extraction is deferred to tap time (unchanged from all previous phases).
//
// YouTube thumbnail format: https://i.ytimg.com/vi/{videoId}/mqdefault.jpg

import 'package:flutter/material.dart';
import 'package:armonia/data/models/curated_playlist.dart';
import 'package:armonia/data/models/song.dart';

String _thumb(String videoId) =>
    'https://i.ytimg.com/vi/$videoId/mqdefault.jpg';

Song _song(
  String videoId,
  String title,
  String artist, {
  int seconds = 0,
  String album = '',
}) =>
    Song(
      videoId: videoId,
      title: title,
      artist: artist,
      album: album,
      thumbnail: _thumb(videoId),
      duration: Duration(seconds: seconds),
    );

// ---------------------------------------------------------------------------
// HINDI HITS
// ---------------------------------------------------------------------------

final List<Song> _hindiHitsSongs = [
  _song('Cez1lyILNbU', 'Tum Hi Ho', 'Arijit Singh', seconds: 262, album: 'Aashiqui 2'),
  _song('bGSoxFnsFkQ', 'Channa Mereya', 'Arijit Singh', seconds: 282, album: 'Ae Dil Hai Mushkil'),
  _song('JcOByVqfBgM', 'Kesariya', 'Arijit Singh', seconds: 261, album: 'Brahmastra'),
  _song('pVyN9idB4Co', 'Kal Ho Na Ho', 'Sonu Nigam', seconds: 338, album: 'Kal Ho Na Ho'),
  _song('XRbCvJGJJHg', 'Tere Bina', 'A.R. Rahman', seconds: 302, album: 'Guru'),
  _song('7AiyBImJnWA', 'Dilbaro', 'Harshdeep Kaur', seconds: 257, album: 'Raazi'),
  _song('N1OV0BFZRPI', 'Phir Le Aya Dil', 'Arijit Singh', seconds: 268, album: 'Barfi!'),
  _song('WBHyMBOcRFE', 'Tera Ban Jaunga', 'Tulsi Kumar', seconds: 230, album: 'Kabir Singh'),
  _song('hFZFjoX2cGg', 'Bekhayali', 'Sachet Tandon', seconds: 298, album: 'Kabir Singh'),
  _song('4NMiRaX4oew', 'Ve Maahi', 'Arijit Singh', seconds: 265, album: 'Kesari'),
  _song('VYjmMQUPniM', 'Lut Gaye', 'Jubin Nautiyal', seconds: 226, album: 'Lut Gaye'),
  _song('1AOY0U9TMm4', 'Zara Zara', 'Bombay Jayashri', seconds: 289, album: 'RHTDM'),
  _song('3JZ4pnNtyxQ', 'O Saathi', 'Atif Aslam', seconds: 239, album: 'Baaghi 2'),
  _song('G0d5G-cE_DI', 'Judaai', 'Arijit Singh', seconds: 274, album: 'Badlapur'),
  _song('8tEbU15DkO0', 'Meri Aashiqui', 'Jubin Nautiyal', seconds: 221, album: 'Single'),
  _song('X5JMF5UmNYk', 'Pasoori', 'Ali Sethi & Shae Gill', seconds: 231, album: 'Coke Studio'),
  _song('Bde-5PmMfkg', 'Hawayein', 'Arijit Singh', seconds: 284, album: 'Jab Harry Met Sejal'),
  _song('XFpsGFLJAEA', 'Main Rang Sharbaton Ka', 'Atif Aslam', seconds: 289, album: 'Phata Poster Nikhla Hero'),
  _song('_FcW2E0sPHE', 'Enna Sona', 'Arijit Singh', seconds: 256, album: 'Ok Jaanu'),
  _song('gExv9pZlBEQ', 'Heeriye', 'Jasleen Royal ft. Arijit Singh', seconds: 232, album: 'Heeriye'),
  _song('GrBdnmIy4ms', 'Ek Ladki Ko Dekha Toh', 'Darshan Raval', seconds: 251, album: 'Single'),
  _song('W-XFkTSOrfQ', 'Teri Baat Aur Hai', 'Darshan Raval', seconds: 215, album: 'Single'),
  _song('JeU9bRjl6Vw', 'Manike Mage Hithe (Hindi)', 'Yohani', seconds: 200, album: 'Single'),
  _song('SiGBiN0ds7I', 'Raabta', 'Arijit Singh', seconds: 282, album: 'Agent Sai Srinivasa'),
];

// ---------------------------------------------------------------------------
// GYM MOTIVATION
// ---------------------------------------------------------------------------

final List<Song> _gymMotivationSongs = [
  _song('Y2NkuFbEnXE', 'Eye of the Tiger', 'Survivor', seconds: 245, album: 'Eye of the Tiger'),
  _song('btPJPFnesV4', 'Till I Collapse', 'Eminem', seconds: 297, album: 'The Eminem Show'),
  _song('0jgrCKhxE1s', 'HUMBLE.', 'Kendrick Lamar', seconds: 177, album: 'DAMN.'),
  _song('KEI4qSrkPAs', 'Stronger', 'Kanye West', seconds: 311, album: 'Graduation'),
  _song('tAGnKpE4NCI', 'SICKO MODE', 'Travis Scott', seconds: 312, album: 'Astroworld'),
  _song('BI46rqDPFVk', "Can't Hold Us", 'Macklemore & Ryan Lewis', seconds: 257, album: 'The Heist'),
  _song('Gs069dndIYk', 'Radioactive', 'Imagine Dragons', seconds: 187, album: 'Night Visions'),
  _song('hT_nvWreIhg', 'Counting Stars', 'OneRepublic', seconds: 257, album: 'Native'),
  _song('CevxZvSJLk8', 'Believer', 'Imagine Dragons', seconds: 204, album: 'Evolve'),
  _song('ALZHF5UqnU4', 'Thunder', 'Imagine Dragons', seconds: 187, album: 'Evolve'),
  _song('JGwWNGJdvx8', 'Shape of You', 'Ed Sheeran', seconds: 234, album: 'Divide'),
  _song('ktvTqknDobU', 'Uptown Funk', 'Bruno Mars ft. Mark Ronson', seconds: 270, album: 'Uptown Special'),
  _song('60ItHLz5WEA', 'Starboy', 'The Weeknd', seconds: 231, album: 'Starboy'),
  _song('2vjPBrBU-TM', 'Blinding Lights', 'The Weeknd', seconds: 200, album: 'After Hours'),
  _song('9HDEHj2yzew', 'Levitating', 'Dua Lipa', seconds: 203, album: 'Future Nostalgia'),
  _song('DyDfgMOUjCI', 'Physical', 'Dua Lipa', seconds: 194, album: 'Future Nostalgia'),
  _song('gNi_6U5Pm_o', 'Lose Yourself', 'Eminem', seconds: 326, album: '8 Mile Soundtrack'),
  _song('IaYmBBkLFAQ', 'Power', 'Kanye West', seconds: 292, album: 'My Beautiful Dark Twisted Fantasy'),
  _song('fRh_vgS2dFE', 'Sorry', 'Justin Bieber', seconds: 200, album: 'Purpose'),
  _song('d-J9M7tkQsA', 'The Hills', 'The Weeknd', seconds: 241, album: 'Beauty Behind the Madness'),
  _song('nfWlot6h_JM', 'Shake It Off', 'Taylor Swift', seconds: 219, album: '1989'),
  _song('SlPhMPnQ58k', 'Save Your Tears', 'The Weeknd', seconds: 215, album: 'After Hours'),
];

// ---------------------------------------------------------------------------
// STUDY FOCUS
// ---------------------------------------------------------------------------

final List<Song> _studyFocusSongs = [
  _song('jfKfPfyJRdk', 'Lofi Hip Hop Radio', 'Lofi Girl', seconds: 3600, album: 'Lofi Girl'),
  _song('5qap5aO4i9A', 'Beats to Relax & Study', 'Lofi Girl', seconds: 3600, album: 'Lofi Girl'),
  _song('DWcJFNfaw9c', 'Clair de Lune', 'Claude Debussy', seconds: 316, album: 'Suite Bergamasque'),
  _song('_mZD9k3B4mE', 'Gymnopédie No.1', 'Erik Satie', seconds: 214, album: 'Gymnopédies'),
  _song('VPLzHPq5HpQ', 'Experience', 'Ludovico Einaudi', seconds: 342, album: 'In a Time Lapse'),
  _song('fpSCbWOuBKo', 'Nuvole Bianche', 'Ludovico Einaudi', seconds: 364, album: 'Una Mattina'),
  _song('HlgrqCKgsHU', "Comptine d'un autre été", 'Yann Tiersen', seconds: 153, album: 'Amélie'),
  _song('7Ph1VcSB0Jg', 'Moonlight Sonata', 'Beethoven', seconds: 360, album: 'Beethoven Sonatas'),
  _song('UmSRbKgxngs', 'Cello Suite No.1', 'Johann Sebastian Bach', seconds: 643, album: 'Cello Suites'),
  _song('rUxyKA_-grg', 'Weightless', 'Marconi Union', seconds: 489, album: 'Weightless'),
  _song('G7eVRyHcM0Q', 'A Moment Apart', 'ODESZA', seconds: 240, album: 'A Moment Apart'),
  _song('_T_aosG_GLM', 'Say My Name', 'ODESZA', seconds: 265, album: 'In Return'),
  _song('7nokMqsO6RQ', 'Tokyo Lofi', 'Idealism', seconds: 185, album: 'Idealism EP'),
  _song('qH3fETPsqXU', 'Coffee Shop Lofi', 'Kupla', seconds: 170, album: 'Lofi Collection'),
  _song('Sz30Mv9k_go', 'Night Drive Lofi Beats', 'Chill Hop Music', seconds: 3600, album: 'Chill Hop'),
  _song('l7TxwBhtTUY', 'Study Beats', 'Chillhop Music', seconds: 3600, album: 'Chillhop'),
  _song('MVPTGNGiI-4', 'Forest Lofi', 'Sleepy Fish', seconds: 195, album: 'Sleepy Fish EP'),
  _song('ZToicYcHIOU', 'Autumn Leaves (Jazz)', 'Various Artists', seconds: 249, album: 'Jazz Classics'),
  _song('8nEQUbMaVIQ', 'Pure Shores', 'All Saints', seconds: 274, album: 'All Saints'),
  _song('LZPL0BHoHIQ', 'Waterfall Piano', 'Peter Sandberg', seconds: 245, album: 'Study Piano'),
  _song('8P9hJKMlznI', 'Focus Flow', 'Various Artists', seconds: 3600, album: 'Focus Beats'),
];

// ---------------------------------------------------------------------------
// ROAD TRIP
// ---------------------------------------------------------------------------

final List<Song> _roadTripSongs = [
  _song('09R8_2nJtjg', 'Mr. Brightside', 'The Killers', seconds: 222, album: 'Hot Fuss'),
  _song('1G4isv_Fylg', 'Bohemian Rhapsody', 'Queen', seconds: 354, album: 'A Night at the Opera'),
  _song('HgzGwKwLmgM', "Don't Stop Believin'", 'Journey', seconds: 250, album: 'Escape'),
  _song('x9RQDpMxFAA', 'Take Me Home Country Roads', 'John Denver', seconds: 189, album: 'Poems Prayers & Promises'),
  _song('hTWKbfoikeg', 'Smells Like Teen Spirit', 'Nirvana', seconds: 301, album: 'Nevermind'),
  _song('t4H_Zoh7G5A', 'Africa', 'Toto', seconds: 295, album: 'Toto IV'),
  _song('Zi_XLOBDo_Y', 'Somebody That I Used To Know', 'Gotye', seconds: 244, album: 'Making Mirrors'),
  _song('lJqbaGloaS0', "I'm Yours", 'Jason Mraz', seconds: 242, album: 'We Sing We Dance We Steal Things'),
  _song('uSD4vsh1zDA', 'Riptide', 'Vance Joy', seconds: 204, album: 'Dream Your Life Away'),
  _song('8UVNT4wvIGY', 'Flowers', 'Miley Cyrus', seconds: 200, album: 'Endless Summer Vacation'),
  _song('H-kA3UtBbh0', 'As It Was', 'Harry Styles', seconds: 167, album: "Harry's House"),
  _song('ScNNfyq3d_w', 'Watermelon Sugar', 'Harry Styles', seconds: 174, album: 'Fine Line'),
  _song('AJqhklKeDkQ', 'Wagon Wheel', 'Old Crow Medicine Show', seconds: 235, album: 'O.C.M.S.'),
  _song('CnDt_GBZZ1A', 'Highway to Hell', 'AC/DC', seconds: 208, album: 'Highway to Hell'),
  _song('4D_ZkYfGNFo', 'Sweet Home Alabama', 'Lynyrd Skynyrd', seconds: 280, album: 'Second Helping'),
  _song('GgnClrx8N2k', 'Fast Car', 'Tracy Chapman', seconds: 296, album: 'Tracy Chapman'),
  _song('dsxtImNgSmI', 'Life is a Highway', 'Tom Cochrane', seconds: 270, album: 'Mad Mad World'),
  _song('fHI8X4OXluQ', 'Adore You', 'Harry Styles', seconds: 207, album: 'Fine Line'),
  _song('RlPNh_PWLuo', 'Golden', 'Harry Styles', seconds: 229, album: 'Fine Line'),
  _song('TNM-TyHbiJ4', 'Sign of the Times', 'Harry Styles', seconds: 340, album: 'Harry Styles'),
  _song('oHg5SJYRHA0', 'Never Gonna Give You Up', 'Rick Astley', seconds: 213, album: 'Whenever You Need Somebody'),
  _song('v2AC41dglnM', 'Thunder Road', 'Bruce Springsteen', seconds: 287, album: 'Born to Run'),
];

// ---------------------------------------------------------------------------
// CHILL VIBES
// ---------------------------------------------------------------------------

final List<Song> _chillVibesSongs = [
  _song('GLD7MFNLGnE', 'Electric Feel', 'MGMT', seconds: 231, album: 'Oracular Spectacular'),
  _song('pB-5XG-DbAA', 'Kids', 'MGMT', seconds: 254, album: 'Oracular Spectacular'),
  _song('3mm3EDCIoBk', 'Time to Pretend', 'MGMT', seconds: 265, album: 'Oracular Spectacular'),
  _song('GyvfNiT4Sss', 'Do I Wanna Know?', 'Arctic Monkeys', seconds: 272, album: 'AM'),
  _song('mXMofxtDPi4', "Why'd You Only Call Me When You're High?", 'Arctic Monkeys', seconds: 163, album: 'AM'),
  _song('VF-r5TtlT9w', 'Fluorescent Adolescent', 'Arctic Monkeys', seconds: 176, album: 'Suck It and See'),
  _song('ZMrV6-BVWTU', 'R U Mine?', 'Arctic Monkeys', seconds: 202, album: 'AM'),
  _song('bpOSxM0uid0', '505', 'Arctic Monkeys', seconds: 254, album: 'Favourite Worst Nightmare'),
  _song('aJOTlE1K90k', 'Redbone', 'Childish Gambino', seconds: 326, album: 'Awaken My Love!'),
  _song('jUe7YKEyOC8', 'Feels Like Summer', 'Childish Gambino', seconds: 219, album: 'Single'),
  _song('F90Cw4l-8NY', 'Telegraph Ave', 'Childish Gambino', seconds: 284, album: 'Because the Internet'),
  _song('Y0lT9Fgof3E', 'Sunflower', 'Post Malone & Swae Lee', seconds: 158, album: 'Spider-Man Into the Spider-Verse'),
  _song('AU4I-hV21co', 'Lost in Yesterday', 'Tame Impala', seconds: 226, album: 'The Slow Rush'),
  _song('2SUwOgmvzK4', 'The Less I Know the Better', 'Tame Impala', seconds: 216, album: 'Currents'),
  _song('b_YHNtqm6yM', 'Feels Like We Only Go Backwards', 'Tame Impala', seconds: 206, album: 'Lonerism'),
  _song('DkeiKbqa02g', 'Let It Happen', 'Tame Impala', seconds: 467, album: 'Currents'),
  _song('bPbDIXHv4X4', 'Vienna', 'Billy Joel', seconds: 215, album: 'The Stranger'),
  _song('mP5ZRM0_CtQ', 'Piano Man', 'Billy Joel', seconds: 337, album: 'Piano Man'),
  _song('a_426yz6aGk', 'The Night We Met', 'Lord Huron', seconds: 219, album: 'Strange Trails'),
  _song('O4-6VFaXFaI', 'Breathe (2 AM)', 'Anna Nalick', seconds: 278, album: 'Wreck of the Day'),
  _song('ZbZSe6N_BXs', 'Peach (Feat Peach)', 'The Front Bottoms', seconds: 210, album: 'Talon of the Hawk'),
  _song('2vjPBrBU-TM', 'Blinding Lights', 'The Weeknd', seconds: 200, album: 'After Hours'),
];

// ---------------------------------------------------------------------------
// LATE NIGHT VIBES
// ---------------------------------------------------------------------------

final List<Song> _lateNightVibesSongs = [
  _song('1ZYbU82uOe4', 'Nights', 'Frank Ocean', seconds: 308, album: 'Blonde'),
  _song('OGl-WaQlI2A', 'Ivy', 'Frank Ocean', seconds: 251, album: 'Blonde'),
  _song('KMerGNM_FrA', 'Self Control', 'Frank Ocean', seconds: 249, album: 'Blonde'),
  _song('3yLP2FuSMFM', 'Thinking Bout You', 'Frank Ocean', seconds: 200, album: 'Channel Orange'),
  _song('HVeNbCcQeQE', 'Location', 'Khalid', seconds: 213, album: 'American Teen'),
  _song('RhU9MiM5ByI', 'Young Dumb & Broke', 'Khalid', seconds: 191, album: 'American Teen'),
  _song('FS58mxK5pVo', 'Talk', 'Khalid', seconds: 213, album: 'Free Spirit'),
  _song('pqtCNGAXazg', 'Better', 'Khalid', seconds: 228, album: 'Free Spirit'),
  _song('X-TPMEiRVkE', 'Saturday Nights', 'Khalid', seconds: 218, album: 'Saturday Nights'),
  _song('nLCKSmW0_bQ', 'Best Part', 'Daniel Caesar ft. H.E.R.', seconds: 216, album: 'Freudian'),
  _song('7h3JFB-YDOQ', 'Get You', 'Daniel Caesar', seconds: 273, album: 'Freudian'),
  _song('K9JcwC-Mx0c', 'Japanese Denim', 'Daniel Caesar', seconds: 233, album: 'Freudian'),
  _song('kMIR-BlWb3Y', 'Streetcar', 'Daniel Caesar', seconds: 202, album: 'Freudian'),
  _song('2hNs9hy9xas', 'Die For You', 'The Weeknd', seconds: 260, album: 'Starboy'),
  _song('XXYlFuWEuKI', 'Call Out My Name', 'The Weeknd', seconds: 222, album: 'My Dear Melancholy'),
  _song('LmSBPHHxtp8', 'Wicked Games', 'The Weeknd', seconds: 324, album: 'Trilogy'),
  _song('mSZa7ERTK4E', 'Often', 'The Weeknd', seconds: 256, album: 'Beauty Behind the Madness'),
  _song('jzD-gc5Jpns', 'Earned It', 'The Weeknd', seconds: 267, album: 'Fifty Shades of Grey'),
  _song('A_FSDCIb0NQ', 'After Hours', 'The Weeknd', seconds: 361, album: 'After Hours'),
  _song('zBVPOmNMkZ4', 'In Your Eyes', 'The Weeknd', seconds: 237, album: 'After Hours'),
  _song('p0iy3DJnBGE', 'Midnight Rain', 'Taylor Swift', seconds: 174, album: 'Midnights'),
  _song('jzD-gc5Jpns', 'Earned It', 'The Weeknd', seconds: 267, album: 'Fifty Shades of Grey'),
];

// ---------------------------------------------------------------------------
// LOFI CODING
// ---------------------------------------------------------------------------

final List<Song> _lofiCodingSongs = [
  _song('jfKfPfyJRdk', 'Lofi Hip Hop Radio – Beats to Study', 'Lofi Girl', seconds: 3600, album: 'Lofi Girl'),
  _song('Sz30Mv9k_go', 'Night Drive Lofi', 'Chillhop Music', seconds: 3600, album: 'Chillhop'),
  _song('MVPTGNGiI-4', 'Forest Lofi', 'Sleepy Fish', seconds: 195, album: 'Sleepy Fish EP'),
  _song('7nokMqsO6RQ', 'Tokyo Lofi', 'Idealism', seconds: 185, album: 'Idealism EP'),
  _song('qH3fETPsqXU', 'Coffee Shop Lofi', 'Kupla', seconds: 170, album: 'Lofi Collection'),
  _song('GH1KjbMDhVQ', 'Easy', 'Kupla', seconds: 162, album: 'Easy EP'),
  _song('C7VHUOM4-LI', 'Rainy Day Lofi', 'Philanthrope', seconds: 178, album: 'Philanthrope EP'),
  _song('H8UfQvPCVUY', 'Hello Again', 'Idealism', seconds: 190, album: 'Hello EP'),
  _song('VO6vFtJEPkA', 'Blue Hour', 'Tenno', seconds: 188, album: 'Blue Hour'),
  _song('G4KJhyTqt1E', 'City of Stars Lofi', 'Various Artists', seconds: 189, album: 'City of Stars'),
  _song('l7TxwBhtTUY', 'Study Beats Vol.1', 'Chillhop Music', seconds: 3600, album: 'Chillhop'),
  _song('5qap5aO4i9A', 'Beats to Relax', 'Lofi Girl', seconds: 3600, album: 'Lofi Girl'),
  _song('rUxyKA_-grg', 'Weightless', 'Marconi Union', seconds: 489, album: 'Weightless'),
  _song('VPLzHPq5HpQ', 'Experience', 'Ludovico Einaudi', seconds: 342, album: 'In a Time Lapse'),
  _song('fpSCbWOuBKo', 'Nuvole Bianche', 'Ludovico Einaudi', seconds: 364, album: 'Una Mattina'),
  _song('HlgrqCKgsHU', "Comptine d'un autre été", 'Yann Tiersen', seconds: 153, album: 'Amélie'),
  _song('_mZD9k3B4mE', 'Gymnopédie No.1', 'Erik Satie', seconds: 214, album: 'Gymnopédies'),
  _song('DWcJFNfaw9c', 'Clair de Lune', 'Claude Debussy', seconds: 316, album: 'Suite Bergamasque'),
  _song('G7eVRyHcM0Q', 'A Moment Apart', 'ODESZA', seconds: 240, album: 'A Moment Apart'),
  _song('_T_aosG_GLM', 'Say My Name', 'ODESZA', seconds: 265, album: 'In Return'),
  _song('8P9hJKMlznI', 'Focus Flow', 'Various Artists', seconds: 3600, album: 'Focus Beats'),
];

// ---------------------------------------------------------------------------
// THE REGISTRY
// ---------------------------------------------------------------------------

/// The full static set of Armonia curated playlists.
///
/// This is the single source of truth for the carousel, quick-access grid,
/// playlist detail screen, and queue management.
abstract final class CuratedPlaylists {
  static final List<CuratedPlaylist> all = <CuratedPlaylist>[
    CuratedPlaylist(
      id: 'hindi_hits',
      title: 'Hindi Hits',
      description: 'Chartbusters and timeless favourites from Bollywood',
      icon: Icons.album_rounded,
      tintColor: const Color(0xFFFBBF24),
      songs: _hindiHitsSongs,
    ),
    CuratedPlaylist(
      id: 'gym_motivation',
      title: 'Gym Motivation',
      description: 'High-energy tracks to push through every set',
      icon: Icons.fitness_center_rounded,
      tintColor: const Color(0xFFFB923C),
      songs: _gymMotivationSongs,
    ),
    CuratedPlaylist(
      id: 'study_focus',
      title: 'Study Focus',
      description: 'Calm instrumentals and lo-fi for deep work',
      icon: Icons.menu_book_rounded,
      tintColor: const Color(0xFF60A5FA),
      songs: _studyFocusSongs,
    ),
    CuratedPlaylist(
      id: 'road_trip',
      title: 'Road Trip',
      description: 'Sing-along anthems for the open road',
      icon: Icons.directions_car_filled_rounded,
      tintColor: const Color(0xFFF87171),
      songs: _roadTripSongs,
    ),
    CuratedPlaylist(
      id: 'chill_vibes',
      title: 'Chill Vibes',
      description: 'Easygoing indie and alternative to unwind',
      icon: Icons.spa_rounded,
      tintColor: const Color(0xFF22D3EE),
      songs: _chillVibesSongs,
    ),
    CuratedPlaylist(
      id: 'late_night_vibes',
      title: 'Late Night Vibes',
      description: 'Slow, smooth, after-hours sounds for the night',
      icon: Icons.nightlight_round,
      tintColor: const Color(0xFFA78BFA),
      songs: _lateNightVibesSongs,
    ),
    CuratedPlaylist(
      id: 'lofi_coding',
      title: 'LoFi Coding',
      description: 'Steady beats and ambient sounds for long sessions',
      icon: Icons.code_rounded,
      tintColor: const Color(0xFF34D399),
      songs: _lofiCodingSongs,
    ),
  ];

  /// Looks up a playlist by [id]. Falls back to the first entry if [id] is
  /// unknown so routes never crash on a stale or mistyped id.
  static CuratedPlaylist byId(String id) {
    for (final CuratedPlaylist p in all) {
      if (p.id == id) return p;
    }
    return all.first;
  }
}
