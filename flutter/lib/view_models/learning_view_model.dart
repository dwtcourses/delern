import 'dart:async';

import 'package:meta/meta.dart';

import '../models/base/stream_muxer.dart';
import '../models/base/transaction.dart';
import '../models/card.dart';
import '../models/deck.dart';
import '../models/scheduled_card.dart';
import '../remote/analytics.dart';

enum LearningUpdateType {
  deckUpdate,
  scheduledCardUpdate,
}

class LearningViewModel {
  ScheduledCardModel get scheduledCard => _scheduledCard;
  ScheduledCardModel _scheduledCard;

  CardModel get card => _card;
  CardModel _card;

  DeckModel get deck => _deck;
  DeckModel _deck;

  final bool allowEdit;

  LearningViewModel({@required DeckModel deck, @required this.allowEdit})
      : _deck = deck;

  Stream<LearningUpdateType> get updates {
    logStartLearning(deck.key);
    return StreamMuxer({
      LearningUpdateType.deckUpdate:
          DeckModel.get(key: deck.key, uid: deck.uid).map((d) => _deck = d),
      LearningUpdateType.scheduledCardUpdate:
          ScheduledCardModel.next(deck).map((casc) {
        _card = casc.card;
        _scheduledCard = casc.scheduledCard;
      }),
      // We deliberately do not subscribe to Card updates (i.e. we only watch
      // ScheduledCard). If the card that the user is looking at right now is
      // updated live, it can result in bad user experience.
    }).map((muxerEvent) => muxerEvent.key);
  }

  Future<void> answer(bool knows, bool learnBeyondHorizon) {
    var cv = _scheduledCard.answer(knows, learnBeyondHorizon);
    return (Transaction()..save(_scheduledCard)..save(cv)).commit();
  }

  Future<void> deleteCard() =>
      (Transaction()..delete(card)..delete(_scheduledCard)).commit();
}
