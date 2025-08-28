import 'package:budget_pro_ai_app/core/models/transaction_model.dart';
import 'package:budget_pro_ai_app/core/services/prediction_service.dart';
import 'package:budget_pro_ai_app/presentation/managers/prediction_cubit/prediction_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PredictionCubit extends Cubit<PredictionState> {
  final PredictionService _predictionService = PredictionService();

  PredictionCubit() : super(PredictionState());

  Future<void> updatePrediction(List<TransactionModel> transactions) async {
    try {
      final predictedExpenses = await _predictionService.predictNextMonthExpenses(transactions);
      emit(PredictionState(predictedExpenses: predictedExpenses));
    } catch (e) {
      emit(PredictionState(predictedExpenses: state.predictedExpenses, error: e.toString()));
    }
  }
}