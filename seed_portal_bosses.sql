-- Seed Portal Bosses Table
-- Run this SQL script after creating the portal_bosses table
-- This populates the table with 45 bosses based on existing opponent data

-- E-Rank Bosses (Levels 1-9)
INSERT INTO portal_bosses (name, rank, image_name, specialization, stat_health, stat_attack, stat_defense, stat_speed, max_hp) VALUES
('ShadowHunter', 'E', 'Opponents/_Stylized Cute Warrior Character (2)', 'Balanced', 150, 12, 12, 12, 300),
('FocusMaster', 'E', 'Opponents/_Stylized Cute Warrior Character (6)', 'Speedster', 105, 15, 8, 18, 210),
('ZenWarrior99', 'E', 'Opponents/_Stylized Cute Warrior Character (9)', 'Tank', 225, 8, 15, 8, 450),
('DeepWorkKing', 'E', 'Opponents/_Stylized Cute Warrior Character (10)', 'Glass Cannon', 90, 18, 6, 12, 180),
('StudyNinja', 'E', 'Opponents/_Stylized Cute Warrior Character (16)', 'Speedster', 105, 12, 8, 18, 210),
('MidnightGrinder', 'E', 'Opponents/_Stylized Cute Warrior Character (17)', 'Balanced', 150, 12, 12, 12, 300),
('FlowStateGod', 'E', 'Opponents/_Stylized Cute Warrior Character (19)', 'Tank', 225, 8, 15, 8, 450),
('HustleHero', 'E', 'Opponents/_Stylized Cute Warrior Character (20)', 'Glass Cannon', 90, 18, 6, 12, 180),
('IronWilliam', 'E', 'Opponents/_Stylized Cute Warrior Character (23)', 'Balanced', 150, 12, 12, 12, 300),
('TaskSlayer', 'E', 'Opponents/_Stylized Cute Warrior Character (24)', 'Speedster', 105, 15, 8, 18, 210);

-- D-Rank Bosses (Levels 10-24)
INSERT INTO portal_bosses (name, rank, image_name, specialization, stat_health, stat_attack, stat_defense, stat_speed, max_hp) VALUES
('PixelMonk', 'D', 'Opponents/_Stylized Cute Warrior Character (25)', 'Tank', 375, 15, 25, 15, 750),
('CodeSamurai', 'D', 'Opponents/_Stylized Cute Warrior Character (26)', 'Balanced', 250, 20, 20, 20, 500),
('BookWorm', 'D', 'Opponents/_Stylized Cute Warrior Character (28)', 'Glass Cannon', 150, 30, 10, 20, 300),
('FocusPhantom', 'D', 'Opponents/_Stylized Cute Warrior Character (33)', 'Speedster', 175, 25, 15, 30, 350),
('GrindMachine', 'D', 'Opponents/_Stylized Cute Warrior Character (35)', 'Balanced', 250, 20, 20, 20, 500),
('AlphaLearner', 'D', 'Opponents/_Stylized Cute Warrior Character (36)', 'Tank', 375, 15, 25, 15, 750),
('SilentScholar', 'D', 'Opponents/_Stylized Cute Warrior Character (40)', 'Speedster', 175, 25, 15, 30, 350),
('RushWarrior', 'D', 'Opponents/_Stylized Cute Warrior Character (42)', 'Glass Cannon', 150, 30, 10, 20, 300),
('ThinkTank', 'D', 'Opponents/_Stylized Cute Warrior Character (46)', 'Tank', 375, 15, 25, 15, 750),
('ChillHustle', 'D', 'Opponents/_Stylized Cute Warrior Character (47)', 'Balanced', 250, 20, 20, 20, 500);

-- C-Rank Bosses (Levels 25-44)
INSERT INTO portal_bosses (name, rank, image_name, specialization, stat_health, stat_attack, stat_defense, stat_speed, max_hp) VALUES
('NeonFocus', 'C', 'Opponents/_Stylized Cute Warrior Character (55)', 'Speedster', 280, 40, 25, 50, 560),
('QuantumMind', 'C', 'Opponents/_Stylized Cute Warrior Character (60)', 'Balanced', 400, 35, 35, 35, 800),
('SteelDiscipline', 'C', 'Opponents/_Stylized Cute Warrior Character (64)', 'Tank', 600, 25, 50, 25, 1200),
('EchoHunter', 'C', 'Opponents/_Stylized Cute Warrior Character (65)', 'Glass Cannon', 240, 50, 15, 35, 480),
('PeakPerformer', 'C', 'Opponents/_Stylized Cute Warrior Character (71)', 'Balanced', 400, 35, 35, 35, 800),
('VoidWalker', 'C', 'Opponents/_Stylized Cute Warrior Character (72)', 'Speedster', 280, 40, 25, 50, 560),
('CrystalClear', 'C', 'Opponents/_Stylized Cute Warrior Character (73)', 'Tank', 600, 25, 50, 25, 1200),
('ZenMaster', 'C', 'Opponents/_Stylized Cute Warrior Character (77)', 'Balanced', 400, 35, 35, 35, 800),
('FlashFocus', 'C', 'Opponents/_Stylized Cute Warrior Character (81)', 'Speedster', 280, 40, 25, 50, 560),
('IceBreaker', 'C', 'Opponents/_Stylized Cute Warrior Character (89)', 'Glass Cannon', 240, 50, 15, 35, 480);

-- B-Rank Bosses (Levels 45-69)
INSERT INTO portal_bosses (name, rank, image_name, specialization, stat_health, stat_attack, stat_defense, stat_speed, max_hp) VALUES
('ThunderStudy', 'B', 'Opponents/_Stylized Cute Warrior Character (102)', 'Speedster', 420, 60, 40, 75, 840),
('WaveRider', 'B', 'Opponents/_Stylized Cute Warrior Character (105)', 'Balanced', 600, 55, 55, 55, 1200),
('MysticGrind', 'B', 'Opponents/_Stylized Cute Warrior Character (187)', 'Tank', 900, 40, 75, 40, 1800),
('PhoenixRise', 'B', 'Opponents/_Stylized Cute Warrior Character (189)', 'Glass Cannon', 360, 75, 25, 55, 720),
('ShadowStep', 'B', 'Opponents/_Stylized Cute Warrior Character (190)', 'Speedster', 420, 60, 40, 75, 840),
('LightSpeed', 'B', 'Opponents/_Stylized Cute Warrior Character (192)', 'Balanced', 600, 55, 55, 55, 1200),
('FrostBite', 'B', 'Opponents/_Stylized Cute Warrior Character (194)', 'Tank', 900, 40, 75, 40, 1800),
('BlazePath', 'B', 'Opponents/_Stylized Cute Warrior Character (195)', 'Glass Cannon', 360, 75, 25, 55, 720),
('StormChaser', 'B', 'Opponents/_Stylized Cute Warrior Character (214)', 'Speedster', 420, 60, 40, 75, 840),
('SilverBullet', 'B', 'Opponents/_Stylized Cute Warrior Character (222)', 'Balanced', 600, 55, 55, 55, 1200);

-- A-Rank Bosses (Levels 70-99)
INSERT INTO portal_bosses (name, rank, image_name, specialization, stat_health, stat_attack, stat_defense, stat_speed, max_hp) VALUES
('GoldRush', 'A', 'Opponents/_Stylized Cute Warrior Character (223)', 'Tank', 1350, 60, 110, 60, 2700),
('DiamondMind', 'A', 'Opponents/_Stylized Cute Warrior Character (226)', 'Balanced', 900, 80, 80, 80, 1800),
('RubyFocus', 'A', 'Opponents/_Stylized Cute Warrior Character (229)', 'Speedster', 630, 90, 60, 110, 1260),
('SapphireWill', 'A', 'Opponents/_Stylized Cute Warrior Character (279)', 'Glass Cannon', 540, 110, 40, 80, 1080),
('EmeraldFlow', 'A', 'Opponents/_Stylized Cute Warrior Character (280)', 'Balanced', 900, 80, 80, 80, 1800);

-- S-Rank Bosses (Levels 100+)
INSERT INTO portal_bosses (name, rank, image_name, specialization, stat_health, stat_attack, stat_defense, stat_speed, max_hp) VALUES
('ShadowHunter', 'S', 'Opponents/_Stylized Cute Warrior Character (2)', 'Tank', 1875, 80, 150, 80, 3750),
('FocusMaster', 'S', 'Opponents/_Stylized Cute Warrior Character (6)', 'Balanced', 1250, 110, 110, 110, 2500),
('ZenWarrior99', 'S', 'Opponents/_Stylized Cute Warrior Character (9)', 'Speedster', 875, 130, 85, 150, 1750),
('DeepWorkKing', 'S', 'Opponents/_Stylized Cute Warrior Character (10)', 'Glass Cannon', 750, 150, 55, 110, 1500),
('StudyNinja', 'S', 'Opponents/_Stylized Cute Warrior Character (16)', 'Balanced', 1250, 110, 110, 110, 2500);

