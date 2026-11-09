import '../../data/repositories/analysis/analysis_repository_stockfish.dart';
import '../../data/repositories/deep_analysis/deep_analysis_repository.dart';
import '../../data/repositories/draw/draw_offer_repository.dart';
import '../../data/repositories/evaluation/evaluation_repository_stockfish.dart';
import '../../data/repositories/maia/maia_repository_device.dart';
import '../../data/repositories/opponent/opponent_repository_device.dart';
import '../../data/repositories/opponent/opponent_repository_maia.dart';
import '../../data/repositories/opponent/opponent_repository_stockfish.dart';
import '../../data/repositories/pace/pace_repository.dart';
import '../../data/repositories/review/game_review_repository.dart';
import '../../data/repositories/tablebase/engine_judge_repository.dart';
import '../../data/services/maia_service.dart';
import '../../data/services/stockfish_service.dart';
import 'core.dart';

/// Os motores (Maia e Stockfish) e o que roda em cima deles.
class EngineDependencies {
  EngineDependencies._({
    required this.analysis,
    required this.reviews,
    required this.pace,
    required this.maiaRepository,
    required this.evaluation,
    required this.opponent,
    required this.deepAnalysis,
    required this.engineJudge,
    required this.drawOffer,
  });

  factory EngineDependencies.create(CoreDependencies core) {
    final assets = core.assets;
    final maia = MaiaService(() => assets.loadBytes(MaiaService.weightsAsset));
    final stockfish = StockfishService();
    final analysis = StockfishAnalysisRepository(stockfish);
    final reviews = LocalGameReviewRepository(core.preferences);
    final pace = AssetPaceRepository(assets);
    final maiaRepository = DeviceMaiaRepository(maia);
    // O mesmo Stockfish do adversário: contra o Maia ele está livre.
    final evaluation = StockfishEvaluationRepository(stockfish);
    return EngineDependencies._(
      analysis: analysis,
      reviews: reviews,
      pace: pace,
      maiaRepository: maiaRepository,
      evaluation: evaluation,
      opponent: DeviceOpponentRepository(
        maia: MaiaOpponentRepository(maia, now: core.now, pace: pace),
        stockfish: StockfishOpponentRepository(stockfish),
      ),
      deepAnalysis: EngineDeepAnalysisRepository(
        analysis: analysis,
        reviews: reviews,
        now: core.now,
      ),
      // O juiz de reserva da lição em roteiro: o mesmo Stockfish (T76).
      engineJudge: StockfishJudgeRepository(stockfish),
      drawOffer: DeviceDrawOfferRepository(
        maia: maiaRepository,
        evaluation: evaluation,
      ),
    );
  }

  final StockfishAnalysisRepository analysis;
  final LocalGameReviewRepository reviews;
  final AssetPaceRepository pace;
  final DeviceMaiaRepository maiaRepository;
  final StockfishEvaluationRepository evaluation;
  final DeviceOpponentRepository opponent;
  final EngineDeepAnalysisRepository deepAnalysis;
  final StockfishJudgeRepository engineJudge;
  final DeviceDrawOfferRepository drawOffer;
}
