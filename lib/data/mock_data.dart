import '../models/trip.dart';

/// Поездка «идёт сейчас» для демо: 6–14 апреля 2026 (для «сегодня» 9 апреля 2026 попадает в диапазон).
final List<Trip> mockTrips = [
  Trip(
    id: 'trip_active_alps',
    name: 'Альпы: текущий выезд',
    destination: 'Швейцария',
    startDate: DateTime(2026, 4, 6),
    endDate: DateTime(2026, 4, 14),
    days: [
      TripDay(
        title: 'День 1',
        date: DateTime(2026, 4, 6),
        description:
            'Прилёт в Цюрих, трансфер и первый вечер у Цюрихского озера.',
        items: const [
          PlaceStop(
            id: 'ps_ch_zrh_air',
            place: Place(
              name: 'Аэропорт Цюрих (ZRH)',
              address: 'Flughafen Zürich',
              kind: PlaceKind.arrivalPoint,
            ),
          ),
          TravelSegment(
            id: 'ts_ch_zrh_city',
            mode: TransportMode.train,
            note: 'S-Bahn / IC ~12–15 мин',
            description: 'До центра или отеля.',
          ),
          PlaceStop(
            id: 'ps_ch_zrh_lake',
            place: Place(
              name: 'Набережная у Цюрихского озера',
              address: 'Bürkliplatz, Zürich',
            ),
          ),
        ],
      ),
      TripDay(
        title: 'День 2',
        date: DateTime(2026, 4, 7),
        description: 'Переезд в Люцерн: мосты, старый город и панорама.',
        items: const [
          PlaceStop(
            id: 'ps_ch_lucerne_station',
            place: Place(
              name: 'Вокзал Люцерн',
              address: 'Bahnhof Luzern',
              kind: PlaceKind.arrivalPoint,
            ),
          ),
          TravelSegment(
            id: 'ts_ch_lucerne_walk',
            mode: TransportMode.car,
            note: 'Пешком ~8 мин',
            description: 'К набережной и мостам.',
          ),
          PlaceStop(
            id: 'ps_ch_chapel',
            place: Place(
              name: 'Часовня моста',
              address: 'Kapellbrücke, Luzern',
            ),
          ),
        ],
      ),
      TripDay(
        title: 'День 3',
        date: DateTime(2026, 4, 8),
        description: 'Путь в Бернский Оберланд: Интерлакен и окрестности.',
        items: const [
          PlaceStop(
            id: 'ps_ch_interlaken',
            place: Place(
              name: 'Интерлакен Вест',
              address: 'Interlaken West Bahnhof',
              kind: PlaceKind.arrivalPoint,
            ),
          ),
          TravelSegment(
            id: 'ts_ch_boat_brienz',
            mode: TransportMode.car,
            note: 'Паром / поезд по расписанию',
            description: 'Вдоль озера или на Harder Kulm.',
          ),
          PlaceStop(
            id: 'ps_ch_harder',
            place: Place(
              name: 'Смотровая Harder Kulm',
              address: 'Harder Kulm, Interlaken',
              notes: 'Фуникулёр, лучше до заката.',
            ),
          ),
        ],
      ),
      TripDay(
        title: 'День 4',
        date: DateTime(2026, 4, 9),
        description:
            'Сегодня в поездке (мок для экрана «сейчас»): Церматт и виды на Маттерхорн.',
        items: const [
          PlaceStop(
            id: 'ps_ch_zermatt',
            place: Place(
              name: 'Церматт',
              address: 'Zermatt, Switzerland',
              notes: 'Авто в деревне не ездят — электромобили и пешком.',
            ),
          ),
          TravelSegment(
            id: 'ts_ch_zermatt_gorner',
            mode: TransportMode.train,
            note: 'Горная железная дорога',
            description: 'Подъём на смотровые по расписанию.',
          ),
          PlaceStop(
            id: 'ps_ch_gornergrat',
            place: Place(
              name: 'Горнерграт',
              address: 'Gornergrat, Zermatt',
            ),
          ),
        ],
      ),
      TripDay(
        title: 'День 5',
        date: DateTime(2026, 4, 10),
        description: 'Ледник и тропы вокруг Церматта; спокойный день в горах.',
        items: const [
          PlaceStop(
            id: 'ps_ch_matterhorn_glacier',
            place: Place(
              name: 'Ледник Маттерхорн (смотровая зона)',
              address: 'Matterhorn Glacier Paradise, Zermatt',
            ),
          ),
          TravelSegment(
            id: 'ts_ch_zermatt_hike',
            mode: TransportMode.car,
            note: 'Пешком / шаттл по тропам',
            description: 'Короткие маршруты без большого набора.',
          ),
          PlaceStop(
            id: 'ps_ch_zermatt_dorf',
            place: Place(
              name: 'Центр Церматта',
              address: 'Bahnhofstrasse, Zermatt',
            ),
          ),
        ],
      ),
      TripDay(
        title: 'День 6',
        date: DateTime(2026, 4, 11),
        description: 'Столица Швейцарии: старый Берн, медвежьи ямы и аркады.',
        items: const [
          PlaceStop(
            id: 'ps_ch_bern_station',
            place: Place(
              name: 'Вокзал Берна',
              address: 'Bern Hauptbahnhof',
              kind: PlaceKind.arrivalPoint,
            ),
          ),
          TravelSegment(
            id: 'ts_ch_bern_old',
            mode: TransportMode.car,
            note: 'Трамвай / пешком',
            description: 'К Старому городу.',
          ),
          PlaceStop(
            id: 'ps_ch_bern_bears',
            place: Place(
              name: 'Медвежий ров (Bärengraben)',
              address: 'Bern',
            ),
          ),
        ],
      ),
      TripDay(
        title: 'День 7',
        date: DateTime(2026, 4, 12),
        description: 'Женева: ООН набережная, Jet d\'Eau, старый город.',
        items: const [
          PlaceStop(
            id: 'ps_ch_geneva_cornavin',
            place: Place(
              name: 'Вокзал Женевы (Cornavin)',
              address: 'Gare de Genève-Cornavin',
              kind: PlaceKind.arrivalPoint,
            ),
          ),
          TravelSegment(
            id: 'ts_ch_geneva_lake',
            mode: TransportMode.car,
            note: 'Пешком вдоль озера',
            description: 'К фонтану и набережной.',
          ),
          PlaceStop(
            id: 'ps_ch_jetdeau',
            place: Place(
              name: 'Фонтан Jet d\'Eau',
              address: 'Quai Gustave-Ador, Genève',
            ),
          ),
        ],
      ),
      TripDay(
        title: 'День 8',
        date: DateTime(2026, 4, 13),
        description: 'Ривьера: Монтрё, замок Шийон и винные террасы.',
        items: const [
          PlaceStop(
            id: 'ps_ch_montreux',
            place: Place(
              name: 'Набережная Монтрё',
              address: 'Montreux, Vaud',
            ),
          ),
          TravelSegment(
            id: 'ts_ch_chillon',
            mode: TransportMode.car,
            note: 'Пешком ~45 мин вдоль озера',
            description: 'Или автобус по желанию.',
          ),
          PlaceStop(
            id: 'ps_ch_chillon',
            place: Place(
              name: 'Замок Шийон',
              address: 'Avenue de Chillon 21, Veytaux',
            ),
          ),
        ],
      ),
      TripDay(
        title: 'День 9',
        date: DateTime(2026, 4, 14),
        description:
            'Ночь перед вылетом у Цюриха; выезд из отеля и рейс домой.',
        items: const [
          PlaceStop(
            id: 'ps_ch_zrh_hotel_checkout',
            place: Place(
              name: 'Отель у аэропорта / Цюрих',
              address: 'Zürich Flughafen / Kloten',
              kind: PlaceKind.hotel,
              notes: 'Чек-аут и короткий переезд в терминал.',
            ),
          ),
          TravelSegment(
            id: 'ts_ch_zrh_departure',
            mode: TransportMode.train,
            note: 'Поезд в аэропорт ~10–12 мин',
            description: 'Из Zürich HB в ZRH.',
          ),
          PlaceStop(
            id: 'ps_ch_zrh_depart',
            place: Place(
              name: 'Вылет из Цюриха (ZRH)',
              address: 'Flughafen Zürich',
              kind: PlaceKind.arrivalPoint,
            ),
          ),
        ],
      ),
    ],
  ),
  Trip(
    id: 'trip_past_1',
    name: 'Париж, выходные',
    destination: 'Франция',
    startDate: DateTime(2025, 11, 7),
    endDate: DateTime(2025, 11, 10),
    days: [
      TripDay(
        title: 'День 1',
        date: DateTime(2025, 11, 7),
        description: 'Приезд и прогулка по центру.',
        items: [
          const PlaceStop(
            id: 'ps_paris_gdn',
            place: Place(
              name: 'Вокзал Gare du Nord',
              address: '18 Rue de Dunkerque, Paris',
              kind: PlaceKind.arrivalPoint,
            ),
          ),
          const TravelSegment(
            id: 'ts_paris_1',
            mode: TransportMode.train,
            note: 'RER B ~25 мин',
            description: 'От вокзала до района отеля.',
          ),
          const PlaceStop(
            id: 'ps_paris_hotel',
            place: Place(
              name: 'Отель Latin Quarter',
              address: '5 Rue des Écoles, Paris',
              kind: PlaceKind.hotel,
            ),
          ),
          const TravelSegment(
            id: 'ts_paris_2',
            mode: TransportMode.car,
            note: 'Пешком 12 мин',
            description: 'Прогулка через квартал Латин.',
          ),
          const PlaceStop(
            id: 'ps_paris_louvre',
            place: Place(
              name: 'Лувр',
              address: 'Rue de Rivoli, Paris',
              notes: 'Билеты лучше заранее.',
              attachments: [
                PlaceAttachment(
                    path: 'louvre_ticket.pdf', displayLabel: 'Билет в Лувр'),
              ],
            ),
          ),
          const PlaceStop(
            id: 'ps_paris_notre_dame',
            place: Place(
              name: 'Нотр-Дам',
              address: '6 Parvis Notre-Dame, Paris',
            ),
          ),
        ],
      ),
      TripDay(
        title: 'День 2',
        date: DateTime(2025, 11, 8),
        description: 'Монмартр и кафе.',
        items: [
          const PlaceStop(
            id: 'ps_paris_sacre',
            place: Place(
              name: 'Сакре-Кёр',
              address: '35 Rue du Chevalier de la Barre, Paris',
            ),
          ),
        ],
      ),
    ],
  ),
  Trip(
    id: 'trip_1',
    name: 'Поездка в Стамбул',
    destination: 'Турция',
    startDate: DateTime(2026, 6, 14),
    endDate: DateTime(2026, 6, 18),
    days: [
      TripDay(
        title: 'День 1',
        date: DateTime(2026, 6, 14),
        description: 'Прилет, заселение и прогулка по центру.',
        items: [
          const PlaceStop(
            id: 'ps_ist_sultan',
            place: Place(
              name: 'Площадь Султанахмет',
              address: 'Sultan Ahmet, Istanbul',
              notes: 'Лучше прийти утром.',
              attachments: [
                PlaceAttachment(
                    path: 'ticket_istanbul_flight.pdf',
                    displayLabel: 'Авиабилет'),
                PlaceAttachment(
                    path: 'hotel_booking.png', displayLabel: 'Бронь отеля'),
              ],
              customLinks: [
                PlaceLink(
                  title: 'Официальный сайт площади',
                  url: 'https://muze.gen.tr/muze-detay/sultanahmet',
                ),
              ],
            ),
          ),
          const PlaceStop(
            id: 'ps_ist_mosque',
            place: Place(
              name: 'Голубая мечеть',
              address: 'Binbirdirek, At Meydani Cd. No:10',
              customLinks: [
                PlaceLink(
                  title: 'Расписание посещения',
                  url: 'https://www.mosquefoundation.com/',
                ),
              ],
            ),
          ),
        ],
      ),
      TripDay(
        title: 'День 2',
        date: DateTime(2026, 6, 15),
        description: 'Круиз по Босфору и местная кухня.',
        items: [
          const PlaceStop(
            id: 'ps_ist_galata',
            place: Place(
              name: 'Галатская башня',
              address: 'Bereketzade, Galata Kulesi',
              attachments: [
                PlaceAttachment(
                    path: 'galata_entry_qr.jpg', displayLabel: 'QR вход'),
              ],
            ),
          ),
          const TravelSegment(
            id: 'ts_istanbul_galata_eminonu',
            mode: TransportMode.car,
            note: 'Пешком ~18 мин, вдоль набережной',
            description: 'Спуск к заливу, вид на мосты.',
          ),
          const PlaceStop(
            id: 'ps_ist_eminonu',
            place: Place(
              name: 'Причал Эминеню',
              address: 'Eminonu Pier, Istanbul',
              kind: PlaceKind.arrivalPoint,
              notes: 'Купить билеты заранее.',
              customLinks: [
                PlaceLink(
                  title: 'Онлайн билеты на круиз',
                  url: 'https://www.sehirhatlari.istanbul/',
                ),
              ],
            ),
          ),
        ],
      ),
    ],
  ),
  Trip(
    id: 'trip_2',
    name: 'Поездка в Рим',
    destination: 'Италия',
    startDate: DateTime(2026, 9, 3),
    endDate: DateTime(2026, 9, 7),
    days: [
      TripDay(
        title: 'День 1',
        date: DateTime(2026, 9, 3),
        description: 'Знакомство с историческим центром.',
        items: [
          const PlaceStop(
            id: 'ps_rome_colosseum',
            place: Place(
              name: 'Колизей',
              address: 'Piazza del Colosseo, 1',
              attachments: [
                PlaceAttachment(
                    path: 'rome_colosseum_ticket.pdf', displayLabel: 'Билет'),
              ],
            ),
          ),
          const TravelSegment(
            id: 'ts_rome_col_forum',
            mode: TransportMode.car,
            note: '3 мин пешком',
            description: 'Короткий переход к форуму.',
          ),
          const PlaceStop(
            id: 'ps_rome_forum',
            place: Place(
              name: 'Римский форум',
              address: 'Via della Salara Vecchia, 5/6',
            ),
          ),
        ],
      ),
    ],
  ),

  /// Демо разделителей месяцев в списке дней: 30–31 мая и 1–2 июня 2026.
  Trip(
    id: 'trip_benelux_two_months',
    name: 'Амстердам и Брюссель',
    destination: 'Нидерланды, Бельгия',
    startDate: DateTime(2026, 5, 30),
    endDate: DateTime(2026, 6, 2),
    days: [
      TripDay(
        title: 'День 1',
        date: DateTime(2026, 5, 30),
        description: 'Прилёт в Амстердам, каналы и первый вечер.',
        items: const [
          PlaceStop(
            id: 'ps_nl_ams_schiphol',
            place: Place(
              name: 'Аэропорт Схипхол',
              address: 'Amsterdam Airport Schiphol',
              kind: PlaceKind.arrivalPoint,
            ),
          ),
          TravelSegment(
            id: 'ts_nl_ams_centraal',
            mode: TransportMode.train,
            note: 'Поезд ~15–20 мин',
            description: 'До Amsterdam Centraal.',
          ),
          PlaceStop(
            id: 'ps_nl_dam',
            place: Place(
              name: 'Площадь Дам',
              address: 'Dam, Amsterdam',
            ),
          ),
        ],
      ),
      TripDay(
        title: 'День 2',
        date: DateTime(2026, 5, 31),
        description: 'Музеи и прогулка по каналам.',
        items: const [
          PlaceStop(
            id: 'ps_nl_rijksmuseum',
            place: Place(
              name: 'Рейксмюсеум',
              address: 'Museumstraat 1, Amsterdam',
            ),
          ),
        ],
      ),
      TripDay(
        title: 'День 3',
        date: DateTime(2026, 6, 1),
        description: 'Поезд в Брюссель, Гранд-Плас и центр.',
        items: const [
          PlaceStop(
            id: 'ps_be_brussels_midi',
            place: Place(
              name: 'Вокзал Bruxelles-Midi',
              address: 'Avenue Fonsny 47, Brussels',
              kind: PlaceKind.arrivalPoint,
            ),
          ),
          TravelSegment(
            id: 'ts_be_to_grand_place',
            mode: TransportMode.train,
            note: 'Метро / пешком',
            description: 'К историческому центру.',
          ),
          PlaceStop(
            id: 'ps_be_grand_place',
            place: Place(
              name: 'Гранд-Плас',
              address: 'Grand Place, Brussels',
            ),
          ),
        ],
      ),
      TripDay(
        title: 'День 4',
        date: DateTime(2026, 6, 2),
        description: 'Атомиум или шопинг; вечером отъезд.',
        items: const [
          PlaceStop(
            id: 'ps_be_atomium',
            place: Place(
              name: 'Атомиум',
              address: 'Square de l\'Atomium, Brussels',
            ),
          ),
        ],
      ),
    ],
  ),
];
