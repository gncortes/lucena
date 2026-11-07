import 'package:flutter/widgets.dart';

/// A apresentação do Pilares do Xadrez (H-VEN-01) e o "Para quem é".
abstract final class CoursePreviewKeys {
  static const sale = Key('coursePreview.sale');
  static const saleScroll = Key('coursePreview.sale.scroll');
  static Key tab(int index) => Key('coursePreview.sale.tab.$index');
  static const buy = Key('coursePreview.sale.buy');
  static const priceCard = Key('coursePreview.sale.price');
  static const planMonthly = Key('coursePreview.sale.price.monthly');
  static const costCompare = Key('coursePreview.sale.cost');
  static Key benefit(int index) => Key('coursePreview.sale.benefit.$index');
  static Key faq(int index) => Key('coursePreview.sale.faq.$index');
  static Key part(int index) => Key('coursePreview.sale.part.$index');
  static Key partHeader(String number) =>
      Key('coursePreview.sale.part.$number.header');
  static Key summaryChapter(int number) =>
      Key('coursePreview.sale.summary.chapter.$number');
  static const audience = Key('coursePreview.sale.audience');
  static const band = Key('coursePreview.band');
  static const bandChart = Key('coursePreview.band.chart');

  // "Sobre o Pilares" (H-VEN-02).
  static const aboutTile = Key('course.details.aboutTile');
  static const details = Key('course.details');
  static Key detailsTab(int index) => Key('course.details.tab.$index');
  static Key detailsPart(int index) => Key('course.details.part.$index');
  static Key detailsFaq(int index) => Key('course.details.faq.$index');
  static const detailsAudience = Key('course.details.audience');
}
