// ==========================================
// DATUMTABEL TESTS
// ==========================================
// Gebruik: plak deze query in Power BI Desktop via
// Transform data > Nieuwe lege query > Geavanceerde editor.
// De query retourneert een tabel met kolommen:
//   TestNummer, TestNaam, Geslaagd, Verwacht, Werkelijk
//
// Alle Geslaagd-waarden moeten true zijn.
// Een false-waarde toont het verschil via Verwacht en Werkelijk.
// ==========================================

let
    // ==========================================
    // INSTELLINGEN (gelijk aan DateTable_NL.pq)
    // ==========================================
    StartJaar = 2020,
    EindJaar = 2035,
    Cultuur = "nl-NL",
    BevrijdingsdagAlleenLustrumjaar = false,
    GoedeVrijdagIsWerkdag = false,

    NuUTC = DateTimeZone.FixedUtcNow(),

    LaatsteZondag = (Jaar as number, Maand as number) as date =>
        let
            LaatsteDag = Date.EndOfMonth(#date(Jaar, Maand, 1)),
            Terug = Date.DayOfWeek(LaatsteDag, Day.Sunday)
        in
            Date.AddDays(LaatsteDag, -Terug),

    UTCJaar = Date.Year(DateTimeZone.RemoveZone(NuUTC)),
    ZomerStart = #datetimezone(UTCJaar, 3, Date.Day(LaatsteZondag(UTCJaar, 3)), 1, 0, 0, 0, 0),
    ZomerEinde = #datetimezone(UTCJaar, 10, Date.Day(LaatsteZondag(UTCJaar, 10)), 1, 0, 0, 0, 0),
    TijdzoneUren = if NuUTC >= ZomerStart and NuUTC < ZomerEinde then 2 else 1,
    Vandaag = Date.From(DateTimeZone.SwitchZone(NuUTC, TijdzoneUren)),

    StartDatum = #date(StartJaar, 1, 1),
    EindDatum = #date(EindJaar, 12, 31),
    AantalDagen = Duration.Days(EindDatum - StartDatum) + 1,

    EerstePaasdag = (Jaar as number) as date =>
        let
            a = Number.Mod(Jaar, 19),
            b = Number.IntegerDivide(Jaar, 100),
            c = Number.Mod(Jaar, 100),
            d = Number.IntegerDivide(b, 4),
            e = Number.Mod(b, 4),
            f = Number.IntegerDivide(b + 8, 25),
            g = Number.IntegerDivide(b - f + 1, 3),
            h = Number.Mod(19*a + b - d - g + 15, 30),
            i = Number.IntegerDivide(c, 4),
            k = Number.Mod(c, 4),
            l = Number.Mod(32 + 2*e + 2*i - h - k, 7),
            m = Number.IntegerDivide(a + 11*h + 22*l, 451),
            n = h + l - 7*m + 114,
            Maand = Number.IntegerDivide(n, 31),
            Dag = Number.Mod(n, 31) + 1
        in
            #date(Jaar, Maand, Dag),

    FeestdagRecords =
        List.Combine(
            List.Transform(
                {StartJaar..EindJaar},
                (J) =>
                    let
                        Pasen = EerstePaasdag(J),
                        Koningsdag =
                            if Date.DayOfWeek(#date(J, 4, 27), Day.Sunday) = 0
                            then #date(J, 4, 26)
                            else #date(J, 4, 27)
                    in
                        {
                            [Datum = #date(J, 1, 1), Feestdag = "Nieuwjaarsdag"],
                            [Datum = Date.AddDays(Pasen, -2), Feestdag = "Goede Vrijdag"],
                            [Datum = Pasen, Feestdag = "Eerste paasdag"],
                            [Datum = Date.AddDays(Pasen, 1), Feestdag = "Tweede paasdag"],
                            [Datum = Koningsdag, Feestdag = "Koningsdag"],
                            [Datum = #date(J, 5, 5), Feestdag = "Bevrijdingsdag"],
                            [Datum = Date.AddDays(Pasen, 39), Feestdag = "Hemelvaartsdag"],
                            [Datum = Date.AddDays(Pasen, 49), Feestdag = "Eerste pinksterdag"],
                            [Datum = Date.AddDays(Pasen, 50), Feestdag = "Tweede pinksterdag"],
                            [Datum = #date(J, 12, 25), Feestdag = "Eerste kerstdag"],
                            [Datum = #date(J, 12, 26), Feestdag = "Tweede kerstdag"]
                        }
            )
        ),

    Feestdagen = Table.TransformColumnTypes(
        Table.FromRecords(FeestdagRecords),
        {{"Datum", type date}, {"Feestdag", type text}}
    ),

    Datums = List.Dates(StartDatum, AantalDagen, #duration(1, 0, 0, 0)),
    DatumTabel = Table.TransformColumnTypes(
        Table.FromList(Datums, Splitter.SplitByNothing(), {"Datum"}),
        {{"Datum", type date}}
    ),

    AttributenToevoegen = Table.AddColumn(
        DatumTabel,
        "Attributen",
        each
            let
                D = [Datum],
                J = Date.Year(D),
                M = Date.Month(D),
                Dag = Date.Day(D),
                Weekdag = Date.DayOfWeek(D, Day.Monday) + 1,
                Kwartaal = Date.QuarterOfYear(D),
                Donderdag = Date.AddDays(D, 4 - Weekdag),
                ISOJaar = Date.Year(Donderdag),
                ISOWeek1Maandag = Date.StartOfWeek(#date(ISOJaar, 1, 4), Day.Monday),
                ISOWeek = Number.IntegerDivide(Duration.Days(Date.StartOfWeek(D, Day.Monday) - ISOWeek1Maandag), 7) + 1,
                RelatiefJaar = J - Date.Year(Vandaag),
                RelatiefKwartaal = (J * 4 + Kwartaal) - (Date.Year(Vandaag) * 4 + Date.QuarterOfYear(Vandaag)),
                RelatieveMaand = (J * 12 + M) - (Date.Year(Vandaag) * 12 + Date.Month(Vandaag)),
                RelatieveWeek = Number.IntegerDivide(Duration.Days(Date.StartOfWeek(D, Day.Monday) - Date.StartOfWeek(Vandaag, Day.Monday)), 7),
                RelatieveDag = Duration.Days(D - Vandaag),
                StartLaatste12Maanden = Date.AddMonths(Date.StartOfMonth(Vandaag), -11),
                StartLaatste30Dagen = Date.AddDays(Vandaag, -29)
            in
                [
                    DatumSleutel = J * 10000 + M * 100 + Dag,
                    Eeuw = Number.IntegerDivide(J - 1, 100) + 1,
                    Jaar = J, Kwartaal = Kwartaal,
                    JaarKwartaal = Text.From(J) & "-K" & Text.From(Kwartaal),
                    JaarKwartaalSortering = J * 10 + Kwartaal,
                    MaandNummer = M, MaandNaam = Date.MonthName(D, Cultuur),
                    MaandAfkorting = Date.ToText(D, "MMM", Cultuur),
                    JaarMaand = Date.ToText(D, "yyyy-MM", Cultuur),
                    JaarMaandSortering = J * 100 + M,
                    DagVanMaand = Dag, DagVanJaar = Date.DayOfYear(D),
                    WeekdagNummer = Weekdag, WeekdagNaam = Date.DayOfWeekName(D, Cultuur),
                    WeekdagAfkorting = Date.ToText(D, "ddd", Cultuur),
                    ISOJaar = ISOJaar, ISOWeek = ISOWeek,
                    ISOJaarWeek = Text.From(ISOJaar) & "-W" & Text.PadStart(Text.From(ISOWeek), 2, "0"),
                    ISOJaarWeekSortering = ISOJaar * 100 + ISOWeek,
                    MaandStart = Date.StartOfMonth(D), MaandEinde = Date.EndOfMonth(D),
                    KwartaalStart = Date.StartOfQuarter(D), KwartaalEinde = Date.EndOfQuarter(D),
                    JaarStart = Date.StartOfYear(D), JaarEinde = Date.EndOfYear(D),
                    IsWeekend = Weekdag >= 6,
                    RelatiefJaar = RelatiefJaar, RelatiefKwartaal = RelatiefKwartaal,
                    RelatieveMaand = RelatieveMaand, RelatieveWeek = RelatieveWeek, RelatieveDag = RelatieveDag,
                    IsVandaag = RelatieveDag = 0, IsHuidigeWeek = RelatieveWeek = 0,
                    IsHuidigeMaand = RelatieveMaand = 0, IsHuidigKwartaal = RelatiefKwartaal = 0, IsHuidigJaar = RelatiefJaar = 0,
                    IsGisteren = RelatieveDag = -1, IsVorigeWeek = RelatieveWeek = -1,
                    IsVorigeMaand = RelatieveMaand = -1, IsVorigKwartaal = RelatiefKwartaal = -1, IsVorigJaar = RelatiefJaar = -1,
                    IsLaatste7Dagen = RelatieveDag >= -6 and RelatieveDag <= 0,
                    IsLaatste30Dagen = D >= StartLaatste30Dagen and D <= Vandaag,
                    IsLaatste12Maanden = D >= StartLaatste12Maanden and D <= Vandaag,
                    IsJaarTotNu = RelatiefJaar = 0 and D <= Vandaag,
                    IsKwartaalTotNu = RelatiefKwartaal = 0 and D <= Vandaag,
                    IsMaandTotNu = RelatieveMaand = 0 and D <= Vandaag,
                    IsToekomst = RelatieveDag > 0
                ]
    ),

    AttribuutNamen = {
        "DatumSleutel", "Eeuw", "Jaar", "Kwartaal",
        "JaarKwartaal", "JaarKwartaalSortering",
        "MaandNummer", "MaandNaam", "MaandAfkorting",
        "JaarMaand", "JaarMaandSortering",
        "DagVanMaand", "DagVanJaar",
        "WeekdagNummer", "WeekdagNaam", "WeekdagAfkorting",
        "ISOJaar", "ISOWeek", "ISOJaarWeek", "ISOJaarWeekSortering",
        "MaandStart", "MaandEinde", "KwartaalStart", "KwartaalEinde", "JaarStart", "JaarEinde",
        "IsWeekend",
        "RelatiefJaar", "RelatiefKwartaal", "RelatieveMaand", "RelatieveWeek", "RelatieveDag",
        "IsVandaag", "IsHuidigeWeek", "IsHuidigeMaand", "IsHuidigKwartaal", "IsHuidigJaar",
        "IsGisteren", "IsVorigeWeek", "IsVorigeMaand", "IsVorigKwartaal", "IsVorigJaar",
        "IsLaatste7Dagen", "IsLaatste30Dagen", "IsLaatste12Maanden",
        "IsJaarTotNu", "IsKwartaalTotNu", "IsMaandTotNu", "IsToekomst"
    },

    AttributenUitvouwen = Table.ExpandRecordColumn(AttributenToevoegen, "Attributen", AttribuutNamen),

    FeestdagenKoppelen = Table.NestedJoin(
        AttributenUitvouwen, {"Datum"}, Feestdagen, {"Datum"}, "FeestdagGegevens", JoinKind.LeftOuter
    ),
    FeestdagenUitvouwen = Table.ExpandTableColumn(FeestdagenKoppelen, "FeestdagGegevens", {"Feestdag"}, {"Feestdag"}),
    IsFeestdagToevoegen = Table.AddColumn(FeestdagenUitvouwen, "IsFeestdag", each [Feestdag] <> null, type logical),

    IsWerkdagToevoegen = Table.AddColumn(
        IsFeestdagToevoegen,
        "IsWerkdag",
        each
            let
                IsUitgesloten =
                    ([Feestdag] = "Bevrijdingsdag"
                        and BevrijdingsdagAlleenLustrumjaar
                        and Number.Mod(Date.Year([Datum]), 5) <> 0)
                    or
                    ([Feestdag] = "Goede Vrijdag" and GoedeVrijdagIsWerkdag)
            in
                not [IsWeekend] and not ([IsFeestdag] and not IsUitgesloten),
        type logical
    ),

    IsSchrikkeldagToevoegen = Table.AddColumn(
        IsWerkdagToevoegen,
        "IsSchrikkeldag",
        each Date.Month([Datum]) = 2 and Date.Day([Datum]) = 29,
        type logical
    ),

    DT = IsSchrikkeldagToevoegen,

    // ==========================================
    // HULPFUNCTIE: zoek één rij op datum
    // ==========================================
    ZoekRij = (d as date) =>
        let
            Gefilterd = Table.SelectRows(DT, each [Datum] = d)
        in
            if Table.RowCount(Gefilterd) = 0 then null else Gefilterd{0},

    // ==========================================
    // TESTDEFINITIES
    // ==========================================
    TestDefinities = {
        // Test 1: Bevrijdingsdag staat altijd in Feestdag (2024, niet-lustrumjaar)
        [
            Nr = 1,
            Naam = "2024-05-05: Feestdag = Bevrijdingsdag",
            Verwacht = "Bevrijdingsdag",
            Werkelijk = let R = ZoekRij(#date(2024, 5, 5)) in if R = null then "(geen rij)" else R[Feestdag]
        ],
        // Test 2: Bevrijdingsdag is niet-werkdag in 2024 bij standaardinstellingen
        [
            Nr = 2,
            Naam = "2024-05-05: IsWerkdag = false (standaard, niet-lustrumjaar)",
            Verwacht = "false",
            Werkelijk = let R = ZoekRij(#date(2024, 5, 5)) in if R = null then "(geen rij)" else Text.Lower(Text.From(R[IsWerkdag]))
        ],
        // Test 3: Bevrijdingsdag is niet-werkdag in 2025 (lustrumjaar)
        [
            Nr = 3,
            Naam = "2025-05-05: IsWerkdag = false (lustrumjaar)",
            Verwacht = "false",
            Werkelijk = let R = ZoekRij(#date(2025, 5, 5)) in if R = null then "(geen rij)" else Text.Lower(Text.From(R[IsWerkdag]))
        ],
        // Test 4: Bevrijdingsdag is niet-werkdag in 2026 bij standaardinstellingen
        [
            Nr = 4,
            Naam = "2026-05-05: IsWerkdag = false (standaard, niet-lustrumjaar)",
            Verwacht = "false",
            Werkelijk = let R = ZoekRij(#date(2026, 5, 5)) in if R = null then "(geen rij)" else Text.Lower(Text.From(R[IsWerkdag]))
        ],
        // Test 5: Bevrijdingsdag is niet-werkdag in 2030 (lustrumjaar)
        [
            Nr = 5,
            Naam = "2030-05-05: IsWerkdag = false (lustrumjaar)",
            Verwacht = "false",
            Werkelijk = let R = ZoekRij(#date(2030, 5, 5)) in if R = null then "(geen rij)" else Text.Lower(Text.From(R[IsWerkdag]))
        ],
        // Test 6: Goede Vrijdag 2025 is niet-werkdag bij standaardinstellingen
        [
            Nr = 6,
            Naam = "2025-04-18: Goede Vrijdag IsWerkdag = false (standaard)",
            Verwacht = "false",
            Werkelijk = let R = ZoekRij(#date(2025, 4, 18)) in if R = null then "(geen rij)" else Text.Lower(Text.From(R[IsWerkdag]))
        ],
        // Test 7: Pasen 2025 = 20 april
        [
            Nr = 7,
            Naam = "2025-04-20: Feestdag = Eerste paasdag",
            Verwacht = "Eerste paasdag",
            Werkelijk = let R = ZoekRij(#date(2025, 4, 20)) in if R = null then "(geen rij)" else R[Feestdag]
        ],
        // Test 8: 2024 is een schrikkeljaar
        [
            Nr = 8,
            Naam = "2024-02-29: IsSchrikkeldag = true",
            Verwacht = "true",
            Werkelijk = let R = ZoekRij(#date(2024, 2, 29)) in if R = null then "(geen rij)" else Text.Lower(Text.From(R[IsSchrikkeldag]))
        ],
        // Test 9: 2025 is geen schrikkeljaar — #date(2025, 2, 29) is een ongeldige datum.
        // Power Query gooit een fout bij het aanmaken van de datumwaarde zelf,
        // dus we vangen die op met try...otherwise.
        [
            Nr = 9,
            Naam = "2025-02-29: rij bestaat niet",
            Verwacht = "(geen rij)",
            Werkelijk =
                let
                    D = try #date(2025, 2, 29) otherwise null
                in
                    if D = null then "(geen rij)"
                    else let R = ZoekRij(D) in if R = null then "(geen rij)" else "rij gevonden"
        ],
        // Test 10: ISO-weeknummer over jaargrens — 30 dec 2024 is week 1 van 2025
        [
            Nr = 10,
            Naam = "2024-12-30: ISOWeek = 1, ISOJaar = 2025",
            Verwacht = "1|2025",
            Werkelijk = let R = ZoekRij(#date(2024, 12, 30)) in if R = null then "(geen rij)" else Text.From(R[ISOWeek]) & "|" & Text.From(R[ISOJaar])
        ],
        // Test 11: Koningsdag 2025 — 27 april is zondag, verschoven naar 26 april
        [
            Nr = 11,
            Naam = "2025-04-26: Feestdag = Koningsdag (verschoven van zondag 27 april)",
            Verwacht = "Koningsdag",
            Werkelijk = let R = ZoekRij(#date(2025, 4, 26)) in if R = null then "(geen rij)" else R[Feestdag]
        ],
        // Test 12: Koningsdag 2030 — 27 april is zaterdag, blijft op 27 april
        [
            Nr = 12,
            Naam = "2030-04-27: Feestdag = Koningsdag (zaterdag, niet verschoven)",
            Verwacht = "Koningsdag",
            Werkelijk = let R = ZoekRij(#date(2030, 4, 27)) in if R = null then "(geen rij)" else R[Feestdag]
        ]
    },

    // ==========================================
    // RESULTATEN
    // ==========================================
    Resultaten = Table.FromRecords(
        List.Transform(
            TestDefinities,
            (T) => [
                TestNummer = T[Nr],
                TestNaam = T[Naam],
                Geslaagd = T[Verwacht] = T[Werkelijk],
                Verwacht = T[Verwacht],
                Werkelijk = T[Werkelijk]
            ]
        )
    )

in
    Resultaten
