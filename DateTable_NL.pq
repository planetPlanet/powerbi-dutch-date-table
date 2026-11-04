
let
    // ==========================================
    // INSTELLINGEN
    // ==========================================
    StartJaar = 2020,
    EindJaar = 2035,
    Cultuur = "nl-NL",

    // Bevrijdingsdag (5 mei) is wettelijk vrij alleen in lustrumjaren (deelbaar door 5),
    // maar de huidige standaard behandelt het elk jaar als niet-werkdag (oorspronkelijk gedrag).
    // Zet op true om het alleen in lustrumjaren als niet-werkdag te behandelen.
    BevrijdingsdagAlleenLustrumjaar = false,

    // Goede Vrijdag is geen officiële Nederlandse feestdag.
    // De huidige standaard behandelt het als niet-werkdag (oorspronkelijk gedrag).
    // Zet op true om Goede Vrijdag als werkdag te behandelen.
    GoedeVrijdagIsWerkdag = false,

    // Huidige datum in Nederlandse tijd.
    // Power BI Service gebruikt doorgaans UTC.
    // Europe/Amsterdam kent zomer- en wintertijd.
    // Gebruik daarom een expliciete tijdzonecorrectie.
    NuUTC = DateTimeZone.FixedUtcNow(),

    // DST-berekening: in de EU gaat de klok vooruit op de laatste zondag van maart
    // om 02:00 lokale wintertijd (= 01:00 UTC) en achteruit op de laatste zondag
    // van oktober om 03:00 CEST (= 01:00 UTC). Uur 1 (UTC) in ZomerStart en
    // ZomerEinde is daarom de correcte grenswaarde.
    LaatsteZondag = (Jaar as number, Maand as number) as date =>
        let
            LaatsteDag = Date.EndOfMonth(#date(Jaar, Maand, 1)),
            Terug = Date.DayOfWeek(LaatsteDag, Day.Sunday)
        in
            Date.AddDays(LaatsteDag, -Terug),

    UTCJaar = Date.Year(DateTimeZone.RemoveZone(NuUTC)),
    ZomerStart = #datetimezone(
        UTCJaar, 3,
        Date.Day(LaatsteZondag(UTCJaar, 3)),
        1, 0, 0, 0, 0
    ),
    ZomerEinde = #datetimezone(
        UTCJaar, 10,
        Date.Day(LaatsteZondag(UTCJaar, 10)),
        1, 0, 0, 0, 0
    ),

    TijdzoneUren =
        if NuUTC >= ZomerStart and NuUTC < ZomerEinde
        then 2
        else 1,

    Vandaag = Date.From(
        DateTimeZone.SwitchZone(NuUTC, TijdzoneUren)
    ),

    StartDatum = #date(StartJaar, 1, 1),
    EindDatum = #date(EindJaar, 12, 31),
    AantalDagen = Duration.Days(EindDatum - StartDatum) + 1,

    // ==========================================
    // PAASDATUM BEREKENEN
    // ==========================================
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

    // ==========================================
    // NEDERLANDSE FEESTDAGEN
    // ==========================================
    FeestdagRecords =
        List.Combine(
            List.Transform(
                {StartJaar..EindJaar},
                (J) =>
                    let
                        Pasen = EerstePaasdag(J),
                        Koningsdag =
                            if Date.DayOfWeek(
                                #date(J, 4, 27),
                                Day.Sunday
                            ) = 0
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

    // ==========================================
    // DATUMTABEL GENEREREN
    // ==========================================
    Datums = List.Dates(
        StartDatum,
        AantalDagen,
        #duration(1, 0, 0, 0)
    ),

    DatumTabel = Table.TransformColumnTypes(
        Table.FromList(
            Datums,
            Splitter.SplitByNothing(),
            {"Datum"}
        ),
        {{"Datum", type date}}
    ),

    // ==========================================
    // KALENDER EN RELATIEVE ATTRIBUTEN
    // ==========================================
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

                // ISO 8601
                Donderdag = Date.AddDays(D, 4 - Weekdag),
                ISOJaar = Date.Year(Donderdag),
                ISOWeek1Maandag = Date.StartOfWeek(
                    #date(ISOJaar, 1, 4),
                    Day.Monday
                ),
                ISOWeek =
                    Number.IntegerDivide(
                        Duration.Days(
                            Date.StartOfWeek(D, Day.Monday)
                            - ISOWeek1Maandag
                        ),
                        7
                    ) + 1,

                // Relatieve periodes
                RelatiefJaar = J - Date.Year(Vandaag),

                RelatiefKwartaal =
                    (J * 4 + Kwartaal)
                    - (
                        Date.Year(Vandaag) * 4
                        + Date.QuarterOfYear(Vandaag)
                    ),

                RelatieveMaand =
                    (J * 12 + M)
                    - (
                        Date.Year(Vandaag) * 12
                        + Date.Month(Vandaag)
                    ),

                RelatieveWeek =
                    Number.IntegerDivide(
                        Duration.Days(
                            Date.StartOfWeek(D, Day.Monday)
                            - Date.StartOfWeek(Vandaag, Day.Monday)
                        ),
                        7
                    ),

                RelatieveDag = Duration.Days(D - Vandaag),

                // Grenzen voor voortschrijdende periodes
                StartLaatste12Maanden =
                    Date.AddMonths(
                        Date.StartOfMonth(Vandaag),
                        -11
                    ),

                StartLaatste30Dagen =
                    Date.AddDays(Vandaag, -29)

            in
                [
                    // Sleutel
                    DatumSleutel = J * 10000 + M * 100 + Dag,

                    // Kalender
                    Eeuw = Number.IntegerDivide(J - 1, 100) + 1,
                    Jaar = J,
                    Kwartaal = Kwartaal,
                    JaarKwartaal = Text.From(J) & "-K" & Text.From(Kwartaal),
                    JaarKwartaalSortering = J * 10 + Kwartaal,

                    MaandNummer = M,
                    MaandNaam = Date.MonthName(D, Cultuur),
                    MaandAfkorting = Date.ToText(D, "MMM", Cultuur),
                    JaarMaand = Date.ToText(D, "yyyy-MM", Cultuur),
                    JaarMaandSortering = J * 100 + M,

                    DagVanMaand = Dag,
                    DagVanJaar = Date.DayOfYear(D),
                    WeekdagNummer = Weekdag,
                    WeekdagNaam = Date.DayOfWeekName(D, Cultuur),
                    WeekdagAfkorting = Date.ToText(D, "ddd", Cultuur),

                    ISOJaar = ISOJaar,
                    ISOWeek = ISOWeek,
                    ISOJaarWeek =
                        Text.From(ISOJaar) & "-W" &
                        Text.PadStart(Text.From(ISOWeek), 2, "0"),
                    ISOJaarWeekSortering = ISOJaar * 100 + ISOWeek,

                    // Kalendergrenzen
                    MaandStart = Date.StartOfMonth(D),
                    MaandEinde = Date.EndOfMonth(D),
                    KwartaalStart = Date.StartOfQuarter(D),
                    KwartaalEinde = Date.EndOfQuarter(D),
                    JaarStart = Date.StartOfYear(D),
                    JaarEinde = Date.EndOfYear(D),

                    // Weekend
                    IsWeekend = Weekdag >= 6,

                    // Numerieke relatieve periodes
                    RelatiefJaar = RelatiefJaar,
                    RelatiefKwartaal = RelatiefKwartaal,
                    RelatieveMaand = RelatieveMaand,
                    RelatieveWeek = RelatieveWeek,
                    RelatieveDag = RelatieveDag,

                    // Huidige periodes
                    IsVandaag = RelatieveDag = 0,
                    IsHuidigeWeek = RelatieveWeek = 0,
                    IsHuidigeMaand = RelatieveMaand = 0,
                    IsHuidigKwartaal = RelatiefKwartaal = 0,
                    IsHuidigJaar = RelatiefJaar = 0,

                    // Vorige periodes
                    IsGisteren = RelatieveDag = -1,
                    IsVorigeWeek = RelatieveWeek = -1,
                    IsVorigeMaand = RelatieveMaand = -1,
                    IsVorigKwartaal = RelatiefKwartaal = -1,
                    IsVorigJaar = RelatiefJaar = -1,

                    // Voortschrijdende periodes
                    IsLaatste7Dagen =
                        RelatieveDag >= -6 and RelatieveDag <= 0,

                    IsLaatste30Dagen =
                        D >= StartLaatste30Dagen and D <= Vandaag,

                    // 12 kalendermaanden inclusief huidige maand
                    IsLaatste12Maanden =
                        D >= StartLaatste12Maanden and D <= Vandaag,

                    // To date
                    IsJaarTotNu =
                        RelatiefJaar = 0 and D <= Vandaag,

                    IsKwartaalTotNu =
                        RelatiefKwartaal = 0 and D <= Vandaag,

                    IsMaandTotNu =
                        RelatieveMaand = 0 and D <= Vandaag,

                    // Toekomst
                    IsToekomst = RelatieveDag > 0
                ]
    ),

    // ==========================================
    // ATTRIBUTEN UITVOUWEN
    // ==========================================
    AttribuutNamen = {
        "DatumSleutel",
        "Eeuw", "Jaar", "Kwartaal",
        "JaarKwartaal", "JaarKwartaalSortering",
        "MaandNummer", "MaandNaam", "MaandAfkorting",
        "JaarMaand", "JaarMaandSortering",
        "DagVanMaand", "DagVanJaar",
        "WeekdagNummer", "WeekdagNaam", "WeekdagAfkorting",
        "ISOJaar", "ISOWeek", "ISOJaarWeek",
        "ISOJaarWeekSortering",
        "MaandStart", "MaandEinde",
        "KwartaalStart", "KwartaalEinde",
        "JaarStart", "JaarEinde",
        "IsWeekend",
        "RelatiefJaar", "RelatiefKwartaal",
        "RelatieveMaand", "RelatieveWeek", "RelatieveDag",
        "IsVandaag", "IsHuidigeWeek",
        "IsHuidigeMaand", "IsHuidigKwartaal", "IsHuidigJaar",
        "IsGisteren", "IsVorigeWeek",
        "IsVorigeMaand", "IsVorigKwartaal", "IsVorigJaar",
        "IsLaatste7Dagen", "IsLaatste30Dagen",
        "IsLaatste12Maanden",
        "IsJaarTotNu", "IsKwartaalTotNu", "IsMaandTotNu",
        "IsToekomst"
    },

    AttributenUitvouwen = Table.ExpandRecordColumn(
        AttributenToevoegen,
        "Attributen",
        AttribuutNamen
    ),

    // ==========================================
    // FEESTDAGEN KOPPELEN
    // ==========================================
    FeestdagenKoppelen = Table.NestedJoin(
        AttributenUitvouwen,
        {"Datum"},
        Feestdagen,
        {"Datum"},
        "FeestdagGegevens",
        JoinKind.LeftOuter
    ),

    FeestdagenUitvouwen = Table.ExpandTableColumn(
        FeestdagenKoppelen,
        "FeestdagGegevens",
        {"Feestdag"},
        {"Feestdag"}
    ),

    IsFeestdagToevoegen = Table.AddColumn(
        FeestdagenUitvouwen,
        "IsFeestdag",
        each [Feestdag] <> null,
        type logical
    ),

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

    // ==========================================
    // DATATYPES INSTELLEN
    // ==========================================
    DatumKolommen = {
        "Datum", "MaandStart", "MaandEinde",
        "KwartaalStart", "KwartaalEinde",
        "JaarStart", "JaarEinde"
    },

    TekstKolommen = {
        "JaarKwartaal", "MaandNaam",
        "MaandAfkorting", "JaarMaand",
        "WeekdagNaam", "WeekdagAfkorting",
        "ISOJaarWeek", "Feestdag"
    },

    LogischeKolommen = {
        "IsWeekend", "IsFeestdag", "IsWerkdag", "IsSchrikkeldag",
        "IsVandaag", "IsHuidigeWeek",
        "IsHuidigeMaand", "IsHuidigKwartaal",
        "IsHuidigJaar", "IsGisteren",
        "IsVorigeWeek", "IsVorigeMaand",
        "IsVorigKwartaal", "IsVorigJaar",
        "IsLaatste7Dagen", "IsLaatste30Dagen",
        "IsLaatste12Maanden",
        "IsJaarTotNu", "IsKwartaalTotNu",
        "IsMaandTotNu", "IsToekomst"
    },

    GeheelGetalKolommen = {
        "DatumSleutel", "Eeuw", "Jaar", "Kwartaal",
        "JaarKwartaalSortering",
        "MaandNummer", "JaarMaandSortering",
        "DagVanMaand", "DagVanJaar",
        "WeekdagNummer", "ISOJaar", "ISOWeek",
        "ISOJaarWeekSortering",
        "RelatiefJaar", "RelatiefKwartaal",
        "RelatieveMaand", "RelatieveWeek",
        "RelatieveDag"
    },

    TypeDefinities =
        List.Transform(DatumKolommen, each {_, type date}) &
        List.Transform(TekstKolommen, each {_, type text}) &
        List.Transform(LogischeKolommen, each {_, type logical}) &
        List.Transform(GeheelGetalKolommen, each {_, Int64.Type}),

    Datatypes = Table.TransformColumnTypes(
        IsSchrikkeldagToevoegen,
        TypeDefinities,
        Cultuur
    ),

    // ==========================================
    // SORTEREN OP DATUM
    // ==========================================
    Gesorteerd = Table.Sort(
        Datatypes,
        {{"Datum", Order.Ascending}}
    )
in
    Gesorteerd
