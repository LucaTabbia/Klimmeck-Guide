import 'env_config.dart';

/// Centralized Cloudinary asset paths.
///
/// All asset paths are relative to the Cloudinary base URL defined in EnvConfig.
/// Use [url] getter to get the full URL for any asset.
class CloudinaryAssets {
  CloudinaryAssets._();

  // ============== Cards ==============
  static const String emptyCardSheet = 'v1761305419/emptyCardSheet_tva16h.svg';
  static const String emptySheet = 'v1757660751/emptySheet_jiip7r.svg';
  static const String bottomEmptySheet =
      'v1757660758/bottomEmptySheet_se1k2l.svg';

  // ============== Bookmarks ==============
  /// Nastri: tornano agli scaffali della Libreria; il rosso segna anche gli
  /// oggetti equipaggiati e le magie attive.
  static const String redBookmarkBack =
      'v1795125391/redBookmarkBack_zazkme.svg';
  static const String greenBookmarkBack =
      'v1795125418/greenBookmarkBack_neyu6b.svg';
  static const String yellowBookmarkBack =
      'v1795125445/yellowBookmarkBack_xry9aq.svg';
  static const String blueBookmarkBack =
      'v1795125794/blueBookmarkBack_vaujdu.svg';

  /// Targhette «Novità» della Libreria, una per libro.
  static const String redBookmark = 'v1795125363/redBookmark_zknzfn.svg';
  static const String greenBookmark = 'v1795125336/greenBookmark_tzcuw7.svg';
  static const String yellowBookmark = 'v1795125310/yellowBookmark_zxtxzr.svg';
  static const String blueBookmark = 'v1795125281/blueBookmark_bqxzs3.svg';

  /// Stendardi con la lettera: filtrano le voci di un libro per iniziale.
  static const Map<String, String> letterBookmarks = {
    'a': 'v1795210098/aBookmarkFilter_ns4jlr.svg',
    'b': 'v1795210027/bBookmarkFilter_pdziij.svg',
    'c': 'v1795209995/cBookmarkFilter_o9pgyu.svg',
    'd': 'v1795209963/dBookmarkFilter_h3sxlz.svg',
    'e': 'v1795209932/eBookmarkFilter_pzpecq.svg',
    'f': 'v1795209899/fBookmarkFilter_mipfty.svg',
    'g': 'v1795209868/gBookmarkFilter_n3favf.svg',
    'h': 'v1795209836/hBookmarkFilter_a0f84e.svg',
    'i': 'v1795209804/IBookmarkFilter_bathh8.svg',
    'j': 'v1795209772/jBookmarkFilter_mwdwjz.svg',
    'k': 'v1795209740/kBookmarkFilter_hqtigg.svg',
    'l': 'v1795209694/lBookmarkFilter_mcojkf.svg',
    'm': 'v1795209662/mBookmarkFilter_jgsln8.svg',
    'n': 'v1795209629/nBookmarkFilter_vfnggz.svg',
    'o': 'v1795209597/oBookmarkFilter_rb7yba.svg',
    'p': 'v1795209565/pBookmarkFilter_tmgm7u.svg',
    'q': 'v1795209533/qBookmarkFilter_fw6e7u.svg',
    'r': 'v1795209501/rBookmarkFilter_a28vzf.svg',
    's': 'v1795209469/sBookmarkFilter_hfmzet.svg',
    't': 'v1795209437/tBookmarkFilter_ujaoay.svg',
    'u': 'v1795209326/uBookmarkFilter_elmrto.svg',
    'v': 'v1795209294/vBookmarkFilter_rf1j7v.svg',
    'w': 'v1795209262/wBookmarkFilter_oq9wzw.svg',
    'x': 'v1795209230/xBookmarkFilter_poultg.svg',
    'y': 'v1795209167/yBookmarkFilter_ckrhej.svg',
    'z': 'v1795209198/zBookmarkFilter_zi9lkk.svg',
  };

  /// Sigillo di ceralacca delle aggiunte: voci del menù, Diario e Profilo.
  static const String newEntrySigil = 'v1795125501/newEntrySigil_kgs8y9.svg';

  // ============== Icons ==============
  static const String arrowDown = 'v1794355792/arrowDown_iqsrzb.svg';

  /// Stessa freccia col bordo più spesso, per la Mappa (UAT 2026-11-14).
  static const String arrowMap = 'v1794671761/arrowMap_ucuc2f.svg';
  static const String healEffect = 'v1757660480/healEffect_jc9bsg.svg';
  static const String completeTransaction =
      'v1757683133/completeTransaction_kptwjx.svg';

  // ============== Coins ==============
  static const String goldCoin = 'v1761328247/goldCoin_newd9b.svg';
  static const String silverCoin = 'v1761328260/silverCoin_u1j3xr.svg';
  static const String copperCoin = 'v1761328274/copperCoin_hgiilc.svg';

  // ============== Shop ==============
  static const String emptySatchel = 'v1761306735/emptySatchel_aqvk1y.svg';
  static const String buy = 'v1757660789/buy_pqj7e9.svg';
  static const String sell = 'v1757660787/sell_x0fw5i.svg';
  static const String comicBalloon = 'v1761422762/comic_balloon_grteoq.svg';
  static const String pencil = 'v1761320846/pencil_wpysez.svg';
  static const String rubber = 'v1761320949/rubber_bnonlz.svg';

  // ============== Menu ==============
  static const String map = 'v1757660699/map_tl5hyy.svg';
  static const String mirror = 'v1757660698/mirror_bhcd8f.svg';
  static const String journal = 'v1757660692/journal_qcnxzk.svg';
  static const String library = 'v1757660694/library_klogbm.svg';
  static const String board = 'v1757660697/board_vlwoja.svg';
  static const String shop = 'v1757660695/shop_xllxop.svg';
  static const String pouch = 'v1757660701/pouch_u5gqtk.svg';
  static const String settings = 'v1792150334/settings_linee3.svg';

  // ============== Library ==============
  static const String bestiary = 'v1757660651/bestiary_w68j2y.svg';
  static const String locations = 'v1757660653/locations_rpz9fc.svg';
  static const String religions = 'v1757660649/religions_vwlitf.svg';
  static const String knowledge = 'v1757660650/knowledge_jhr4ad.svg';

  /// Libri aperti: lo scaffale li mostra quando contengono una novità.
  static const String bestiaryOpen = 'v1795124692/bestiaryOpen_yxaped.svg';
  static const String locationsOpen = 'v1795124950/locationsOpen_z24lwc.svg';
  static const String religionsOpen = 'v1795124666/religionsOpen_mqyfk2.svg';
  static const String knowledgeOpen = 'v1795124977/knowledgeOpen_p6fbty.svg';

  // ============== Quest Sheets ==============
  static const String questSheet1 = 'v1757660768/questSheet1_c0hswz.svg';
  static const String questSheet2 = 'v1757660778/questSheet2_ekuuzv.svg';
  static const String questSheetTorn1 =
      'v1794313623/tornQuestSheet1_jo92rm.svg';
  static const String questSheetTorn2 =
      'v1794313329/tornQuestSheet2_gm4nz0.svg';
  static const String jobSheet1 = 'v1757660765/jobSheet1_osfobz.svg';
  static const String jobSheet2 = 'v1757660773/jobSheet2_dgkg6x.svg';
  static const String jobTornSheet1 = 'v1794329019/tornJobSheet1_ivb31s.svg';
  static const String jobTornSheet2 = 'v1794329024/tornJobSheet2_muovna.svg';
  static const String healSheet1 = 'v1794329008/healSheet1_as1rng.svg';
  static const String healSheet2 = 'v1794329013/healSheet2_yosyxa.svg';
  static const String healTornSheet1 = 'v1794329028/tornHealSheet1_am4kxg.svg';
  static const String healTornSheet2 = 'v1794329034/tornHealSheet2_cppkog.svg';
  static const String announcementSheet1 =
      'v1757660770/announcementSheet1_bmh8f2.svg';
  static const String announcementSheet2 =
      'v1757660776/announcementSheet2_tpub5j.svg';
  static const String announcementTornSheet1 =
      'v1794303769/tornAnnouncementSheet1_ez2vyw.svg';
  static const String announcementTornSheet2 =
      'v1794303777/tornAnnouncementSheet2_ayfvwu.svg';
  static const String magicSheet = 'v1794357947/magicSheet_lkkqp3.svg';
  static const String magicTornSheet = 'v1794321051/tornMagicSheet_f8gu75.svg';
  static const String shamanicSheet = 'v1794764350/shamanicSheet_ytxu1n.svg';
  static const String shamanicTornSheet =
      'v1794764330/tornShamanicSheet_exdyou.svg';
  static const String voidSheet = 'v1794764361/voidSheet_iyocqb.svg';
  static const String voidTornSheet = 'v1794764340/tornVoidSheet_h4sp3g.svg';
  static const String huntSheet1 = 'v1794324911/gameSheet1_togp4w.svg';
  static const String huntSheet2 = 'v1794324912/gameSheet2_zrmzpe.svg';
  static const String huntTornSheet1 = 'v1794324905/tornGameSheet1_ruztfx.svg';
  static const String huntTornSheet2 = 'v1794324906/tornGameSheet2_j1xtv6.svg';
  static const String guardSheet1 = 'v1794322926/guardSheet1_yfzvwp.svg';
  static const String guardSheet2 = 'v1794322931/guardSheet2_g7rlqv.svg';
  static const String guardTornSheet1 =
      'v1794322936/tornGuardSheet1_tsxzu5.svg';
  static const String guardTornSheet2 =
      'v1794322939/tornGuardSheet2_aqqbsj.svg';
  static const String crimeSheet1 = 'v1757660763/crimeSheet1_yhl3tp.svg';
  static const String crimeSheet2 = 'v1794314260/crimeSheet2_kenql4.svg';
  static const String crimeTornSheet1 =
      'v1794321444/tornCrimeSheet1_digaof.svg';
  static const String crimeTornSheet2 =
      'v1794321440/tornCrimeSheet2_z2jugi.svg';
  static const String worldMissionSheet =
      'v1794330767/worldMissionSheet_uvximo.svg';
  static const String worldMissionTornSheet =
      'v1794330793/tornWorldMissionSheet_xaijpq.svg';
  static const String storySheet1 = 'v1757660783/storySheet1_evrqbp.svg';
  static const String storySheet2 = 'v1757660774/storySheet2_jsq0nv.svg';
  static const String storyTornSheet1 =
      'v1794312688/tornStorySheet1_jyoucq.svg';
  static const String storyTornSheet2 =
      'v1794314149/tornStorySheet2_otpfcb.svg';
  static const String bossSheet1 = 'v1794330835/bossSheet_kmcubi.svg';
  static const String bossSheet2 = 'v1794331761/bossSheet2_jpfofw.svg';
  static const String bossTornSheet1 = 'v1794346460/tornBossSheet1_aua3ms.svg';
  static const String bossTornSheet2 = 'v1794346467/tornBossSheet2_oi6v2x.svg';
  static const String aidSheet1 = 'v1794331772/aidSheet1_bv1und.svg';
  static const String aidSheet2 = 'v1794331778/aidSheet2_iuxlwt.svg';
  static const String aidTornSheet1 = 'v1794333401/tornAidSheet1_gbxr9p.svg';
  static const String aidTornSheet2 = 'v1794333419/tornAidSheet2_t4eep5.svg';
  static const String enemySheet1 = 'v1757660781/huntSheet1_ufnh7p.svg';
  static const String enemySheet2 = 'v1757660779/huntSheet2_to0gfr.svg';
  static const String enemyTornSheet1 = 'v1794313032/tornHuntSheet1_tk1xqh.svg';
  static const String enemyTornSheet2 = 'v1794312697/tornHuntSheet2_kf1oy7.svg';

  // ============== Pawns ==============
  static const String adventurerFemalePawn =
      'v1757660709/adventurerFemalePawn_btrphw.svg';
  static const String adventurerMalePawn =
      'v1757660710/adventurerMalePawn_eruq7l.svg';
  static const String huntPawn = 'v1757660721/huntPawn_h7bdwj.svg';
  static const String aidPawn = 'v1757660712/aidPawn_zyoz99.svg';
  static const String enemyPawn = 'v1757660715/enemyPawn_c4vstz.svg';
  static const String worldMissionPawn =
      'v1757660713/worldMissionPawn_bjjzc0.svg';
  static const String bossPawn = 'v1757660719/bossPawn_vsz4pf.svg';
  static const String dungeonPawn = 'v1757660716/dungeonPawn_bhbatx.svg';
  static const String storyPawn = 'v1757660718/storyPawn_rvclmp.svg';

  // ============== Equipment (Male) ==============
  static const String maleHelmet = 'v1757660564/maleHelmet_zcqpao.svg';
  static const String maleChestPiece = 'v1757660572/maleChestPiece_ao3f8d.svg';
  static const String maleGloves = 'v1757660570/maleGloves_vw0mf1.svg';
  static const String maleBoots = 'v1757660560/maleBoots_pyhlnf.svg';
  static const String pants = 'v1757660563/pants_hrweqf.svg';
  static const String maleMannequin = 'v1757660558/maleMannequin_ll7j5l.svg';

  // ============== Equipment (Female) ==============
  static const String femaleHelmet = 'v1757682307/femaleHelmet_owbdne.svg';
  static const String femaleChestPiece =
      'v1757660571/femaleChestPiece_g3xa67.svg';
  static const String femaleGloves = 'v1757660562/femaleGloves_v09nho.svg';
  static const String femaleBoots = 'v1757660573/femaleBoots_ptmefq.svg';
  static const String skirt = 'v1757660574/skirt_cfenoz.svg';
  static const String femaleMannequin =
      'v1757660559/femaleMannequin_y04ola.svg';

  // ============== Title Badges ==============
  static const String rookieRank = 'v1794917360/rookieRank_uyzpcg.svg';
  static const String adventurerRank = 'v1794917377/adventurerRank_puudto.svg';
  static const String paladinRank = 'v1794917343/paladinRank_vjrhdp.svg';
  static const String mageRank = 'v1794917322/mageRank_lxeico.svg';
  static const String heroRank = 'v1794917417/heroRank_lvz6fy.svg';
  static const String legendRank = 'v1794917396/legendRank_gd8ctj.svg';

  // ============== Spell Origins ==============
  static const String arcaneOrigin = 'v1794764154/arcaneOrigin_retjhh.svg';
  static const String shamanicOrigin = 'v1794764172/shamanicOrigin_vkxq6d.svg';
  static const String voidOrigin = 'v1794764163/voidOrigin_mxgwls.svg';

  // ============== Use Types ==============
  static const String defenseUse = 'v1757660804/defenseUse_tuhdja.svg';
  static const String attackUse = 'v1757660802/attackUse_plbzx7.svg';
  static const String controlUse = 'v1757660807/controlUse_ua2bpj.svg';
  static const String illusionUse = 'v1757660809/illusionUse_gxy4x3.svg';
  static const String charmUse = 'v1794358489/charmUse_koawq4.svg';
  static const String confuseUse = 'v1794358494/confuseUse_xhvanu.svg';
  static const String enhanceUse = 'v1757660813/enhanceUse_sodazm.svg';
  static const String infuseUse = 'v1794359037/infuseUse_mfz3cu.svg';
  static const String healUse = 'v1793889299/heal_edhg35.svg';

  // ============== Injury Effects ==============
  static const String movementInjury = 'v1757660619/movementInjury_p2afa1.svg';
  static const String visionInjury = 'v1757660621/visionInjury_co2nry.svg';
  static const String bleedingInjury = 'v1757660617/bleedingInjury_rptyig.svg';
  static const String painInjury = 'v1757660627/painInjury_qxcb2z.svg';
  static const String paralysisInjury =
      'v1757660626/paralysisInjury_zmnbhi.svg';
  static const String infectionInjury =
      'v1757660628/infectionInjury_fwdxie.svg';
  static const String consciousnessInjury =
      'v1757660622/consciousnessInjury_bav1ef.svg';
  static const String staminaInjury = 'v1757660625/staminaInjury_jtonqa.svg';
  static const String poisonInjury = 'v1757660623/poisonInjury_qv9hpg.svg';
  static const String burnInjury = 'v1757660620/burnInjury_bp59xq.svg';

  // ============== Equip Types ==============
  static const String helmetType = 'v1757660597/helmetType_u3gvxz.svg';
  static const String chestType = 'v1757660600/chestType_ythx19.svg';
  static const String bootsType = 'v1757660599/bootsType_w772pg.svg';
  static const String greavesType = 'v1757660601/greavesType_enhgpl.svg';
  static const String weaponType = 'v1757660594/weaponType_i5qe0s.svg';
  static const String shieldType = 'v1757660603/shieldType_mbquox.svg';
  static const String glovesType = 'v1757660596/glovesType_dyybio.svg';
  static const String ringType = 'v1757660595/ringType_qmb6bn.svg';
  static const String necklaceType = 'v1757660598/necklaceType_wrpomm.svg';

  // ============== Energy Types ==============
  static const String fireEnergy = 'v1757660512/fireEnergy_cbz3fo.svg';
  static const String iceEnergy = 'v1757660519/iceEnergy_igf4o0.svg';
  static const String lightningEnergy =
      'v1757660512/lightningEnergy_xldvl8.svg';
  static const String acidEnergy = 'v1757660513/acidEnergy_frxlo5.svg';
  static const String poisonEnergy = 'v1757660514/poisonEnergy_vplheq.svg';
  static const String thunderEnergy = 'v1757660517/thunderEnergy_nx8anb.svg';
  static const String forceEnergy = 'v1757660514/forceEnergy_blou6p.svg';
  static const String necroticEnergy = 'v1757660518/necroticEnergy_vknlaj.svg';
  static const String radiantEnergy = 'v1757660516/radiantEnergy_zhv2ay.svg';
  static const String psychicEnergy = 'v1757660516/psychicEnergy_isslea.svg';
  static const String enhancingEnergy =
      'v1757660519/enhancingEnergy_sdt2ao.svg';

  // ============== Effect Types ==============
  static const String noneEffect = 'v1757660482/noneEffect_e6g4b5.svg';
  static const String hungerEffect = 'v1757660483/hungerEffect_mxqqze.svg';
  static const String munitionEffect = 'v1757660484/munitionEffect_cdhllj.svg';
  static const String explorationEffect =
      'v1757660481/explorationEffect_owljlv.svg';

  // ============== Damage Types ==============
  static const String bluntDamage = 'v1757660455/bluntDamage_wwusuu.svg';
  static const String cutDamage = 'v1757660455/cutDamage_kgophy.svg';
  static const String pierceDamage = 'v1757660455/pierceDamage_lr2wyv.svg';

  // ============== Cities ==============
  static const String cliffbreak = 'v1757595092/cliffbreak_kubtyw.svg';
  static const String valantar = 'v1757595096/main/cities/valantar_jht0vo.svg';
  static const String mirwen = 'v1757595094/main/cities/mirwen_vmwejh.svg';
  static const String elfCapital = 'v1761435134/elfCapital_fbv52w.svg';
  static const String bellport = 'v1757595092/bellport_n9e6iu.svg';
  static const String virnen = 'v1757595094/main/cities/virnen_rpc5td.svg';
  static const String flameSouthCapital =
      'v1761436505/flameSouthCapital_yn2ogj.svg';
  static const String morrulir = 'v1757595095/main/cities/morrulir_vccu71.svg';
  static const String liberiaCapital =
      'v1757595094/main/cities/liberia_vgiq6j.svg';
  static const String ferrion = 'v1757595093/ferrion_bnnvkh.svg';
  static const String necrorian =
      'v1757595093/main/cities/necrorian_lvdrxm.svg';
  static const String talmvere = 'v1757595093/talmvere_q12m1l.svg';
  static const String drusteaCity = 'v1761435132/drusteaCity_vqjl3j.svg';
  static const String drusteaVillage = 'v1761435123/drusteaVillage_gdtasn.svg';
  static const String drusteaSeaCity = 'v1761435129/drusteaSeaCity_rqwfuc.svg';
  static const String aarakocraVillage =
      'v1794764202/aarakocraVillage_z7n1rz.svg';
  static const String aarakocraCapital =
      'v1794764223/aarakocraCapital_affl5r.svg';
  static const String valanVillage = 'v1761435122/valanVillage_c8lwqm.svg';
  static const String valanCity = 'v1761435122/valanCity_eu3hx8.svg';
  static const String valanSeaCity = 'v1762562435/valanSeaCity_ilrsu5.svg';
  static const String mirwaCity = 'v1761435121/mirwaCity_bbmrpb.svg';
  static const String mirwaSeaCity = 'v1762562437/mirwaSeaCity_cl5fba.svg';
  static const String mirwaVillage = 'v1761436515/mirwaVillage_jf2ckt.svg';
  static const String desertVillage = 'v1761435139/desertVillage_b4jsgf.svg';
  static const String tropicalVillage =
      'v1761435632/tropicalVillage_atpskz.svg';
  static const String mountainVillage =
      'v1761435131/mountainVillage_sf6dav.svg';
  static const String dragonbornCapital =
      'v1794764233/dragonbornCapital_uyedhh.svg';
  static const String dragonbornVillage =
      'v1794764212/dragonbornVillage_doclsu.svg';
  static const String northVillage = 'v1761435143/northVillage_pymya2.svg';
  static const String forestVillage = 'v1761435131/forestVillage_efgzxw.svg';
  static const String flameCity = 'v1761435135/flameCity_x3iitp.svg';
  static const String flameVillage = 'v1761435124/flameVillage_bv11si.svg';
  static const String motherCity = 'v1761435119/motherCity_tsadv7.svg';
  static const String motherVillage = 'v1761435120/motherVillage_i3sig1.svg';
  static const String liberiaCity = 'v1761435121/liberiaCity_m0epfq.svg';
  static const String liberiaVillage = 'v1761435127/liberiaVillage_pekxru.svg';

  /// Get full URL for an asset path
  static String url(String assetPath) => EnvConfig.cloudinaryUrl(assetPath);
}
