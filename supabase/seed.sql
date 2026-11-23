-- =====================================================================
-- Hidden Tunisia - starter destinations (created_by is NULL: no owner)
-- Run AFTER schema.sql, in the SQL Editor.
-- Photos come from Wikimedia Commons; places without a photo show a
-- green placeholder in the app.
-- =====================================================================

insert into public.places
  (name, city, description, category, image_url, base_rating, latitude, longitude, address)
values
('Café des Délices', 'Sidi Bou Said',
 'A terrace café perched on the cliff above the Gulf of Tunis. Order mint tea with pine nuts and enjoy the blue-and-white village and the sea below. Come early to avoid the crowds.',
 'cafes', 'https://commons.wikimedia.org/wiki/Special:FilePath/Door_Sidi_Bou_Said.jpg?width=900',
 4.7, 36.8702, 10.3478, 'Rue Sidi Chabaane, Sidi Bou Said 2026'),

('Medina Rooftop Terraces', 'Tunis',
 'Hidden above the souks, several rooftop cafés look over the domes and minarets of the UNESCO-listed Medina. Climb the narrow stairs for coffee and a quiet break from the bustle.',
 'cafes', 'https://commons.wikimedia.org/wiki/Special:FilePath/Street_in_the_medina_of_Tunis_01.jpg?width=900',
 4.5, 36.7983, 10.1706, 'Souk El Attarine, Medina of Tunis'),

('Bizerte Old Port & Kasbah', 'Bizerte',
 'Colourful fishing boats, a Spanish fort and the narrow lanes of the Kasbah make this the most charming corner of Tunisia''s northernmost city. Try grilled fish by the water.',
 'historical', 'https://commons.wikimedia.org/wiki/Special:FilePath/The_old_port_of_Bizerte_01.jpg?width=900',
 4.6, 37.2744, 9.8739, 'Vieux Port, Bizerte 7000'),

('Ras Angela Lighthouse', 'Bizerte',
 'The northernmost point of Africa. Rugged cliffs, strong winds and endless Mediterranean views: a perfect spot at sunrise.',
 'viewpoints', null, 4.4, 37.3411, 9.7506, 'Cap Blanc / Ras Angela, Bizerte'),

('Potters'' Quarter of Nabeul', 'Nabeul',
 'Nabeul has been famous for its ceramics for centuries. Visit small workshops, watch artisans paint plates by hand and take home a unique piece.',
 'historical', 'https://commons.wikimedia.org/wiki/Special:FilePath/Potter_in_Nabeul.jpg?width=900',
 4.3, 36.4513, 10.7357, 'Rue Ali Belhouane, Nabeul 8000'),

('El Haouaria Roman Caves', 'El Haouaria, Cap Bon',
 'Ancient Roman quarries carved into the cliffs at the tip of Cap Bon. The cave stones were once shipped to Carthage. Nearby you can watch falcons and enjoy the sea.',
 'nature', 'https://commons.wikimedia.org/wiki/Special:FilePath/Cap_Bon_from_El_Haouaria_village.JPG?width=900',
 4.6, 37.0595, 11.0210, 'Grottes romaines, El Haouaria 8045'),

('Temple of the Waters', 'Zaghouan',
 'A Roman nymphaeum built in the 2nd century to start the aqueduct that supplied Carthage. Behind it rises Jebel Zaghouan, great for hiking.',
 'historical', null, 4.5, 36.4010, 10.1428, 'Nymphaeum, Zaghouan 1100'),

('Great Mosque of Kairouan', 'Kairouan',
 'Founded in 670, one of the oldest and most important places of worship in North Africa. Admire the huge courtyard, the minaret and the forest of Roman columns.',
 'historical', 'https://commons.wikimedia.org/wiki/Special:FilePath/Great_Mosque_of_Kairouan_minaret_view_01.jpg?width=900',
 4.8, 35.6804, 10.0986, 'Rue Okba Ibn Nafaa, Kairouan 3100'),

('Tozeur Palm Grove', 'Tozeur',
 'Over 400,000 palm trees fed by natural springs. Ride a horse carriage through shady paths and taste fresh dates at the source.',
 'nature', null, 4.5, 33.9197, 8.1335, 'Palmeraie de Tozeur, Tozeur 2200'),

('Chebika Mountain Oasis', 'Tozeur',
 'A hidden oasis at the foot of the Atlas, with a waterfall, palm trees and wide views over the salt flats and the Algerian border.',
 'viewpoints', null, 4.7, 34.3167, 7.9500, 'Chebika, Tozeur Governorate'),

('Matmata Troglodyte Houses', 'Matmata',
 'Underground Berber homes dug around open courtyards to escape the heat. Some are open for visits and even used as guesthouses.',
 'historical', null, 4.4, 33.5436, 9.9690, 'Matmata Nouvelle, Gabès Governorate'),

('Houmt Souk Fish Port', 'Djerba',
 'Small family restaurants next to the harbour serve the catch of the day: grilled fish, octopus and traditional Djerbian couscous.',
 'restaurants', 'https://commons.wikimedia.org/wiki/Special:FilePath/Djerba_-_Market_in_Houmt_Souk.jpg?width=900',
 4.4, 33.8754, 10.8574, 'Port de pêche, Houmt Souk 4180'),

('Genoese Fort of Tabarka', 'Tabarka',
 'A 16th-century fort on a rocky islet linked to the mainland. The top gives a fantastic panorama of the coral coast and the wooded hills.',
 'viewpoints', null, 4.5, 36.9586, 8.7544, 'Île de Tabarka, Tabarka 8110'),

('Cap Serrat Wild Beach', 'Sejnane, Bizerte',
 'Golden sand, clear water and almost nobody around. This wild beach is reached by a dirt track, so bring water and food.',
 'beaches', null, 4.8, 37.2333, 9.2167, 'Cap Serrat, Bizerte Governorate'),

('Raf Raf Beach', 'Raf Raf',
 'A relaxed fishing village with a long sandy beach below Ras Sidi Ali el Mekki. Enjoy fresh fish at the little restaurants.',
 'beaches', null, 4.2, 37.1893, 10.1861, 'Plage de Raf Raf, Bizerte Governorate'),

('Ain Draham Cork Oak Forest', 'Ain Draham',
 'Misty mountains and thick cork oak forests that feel more like Europe than the Sahara. Great for walks and cosy wooden chalets.',
 'nature', null, 4.6, 36.7752, 8.6903, 'Forêt de Aïn Draham, Jendouba Governorate');
