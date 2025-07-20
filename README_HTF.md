# Работа с htf.mqh

`htf.mqh` содержит вспомогательные классы для построения баров более высокого таймфрейма (HTF) на основе имеющихся баров меньшего таймфрейма.

## Основные классы

### `CBarStorage`
Хранит данные одного бара: время открытия/закрытия, значения OHLC. Также предоставляет методы:
- `BarToString()` – текстовое представление бара.
- `GetPrice(ENUM_APPLIED_PRICE price)` – получить цену бара по типу (`PRICE_OPEN`, `PRICE_HIGH`, и т.д.).

### `CHTF`
Агрегатор, который собирает последовательность баров HTF. Основные методы:
- `saveInputs(int dayStartHour, int periodMinutes)` – устанавливает начальный час дня и длительность одного HTF-бара в минутах.
- `OnInitCalc()` – очистка и первичная подготовка перед расчётом.
- `Calc(int rates_total, int prev_calculated)` – вызывается из `OnCalculate` индикатора для обновления агрегированных баров.
- `getCurrentBarTimeOpen()` – время открытия текущего собираемого бара.
- `GetOHLC(datetime &time[], double &open[], double &high[], double &low[], double &close[])` – выгружает массивы сформированных баров.

## Пример использования
```mq4
#include "htf.mqh"

CHTF htf;

int OnInit()
{
    // Строим часовые бары из минутных
    htf.saveInputs(0, 60);
    htf.OnInitCalc();
    return(INIT_SUCCEEDED);
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    // обновляем состояние агрегатора
    htf.Calc(rates_total, prev_calculated);

    // получаем готовые данные HTF
    datetime timeHTF[];
    double openHTF[], highHTF[], lowHTF[], closeHTF[];
    htf.GetOHLC(timeHTF, openHTF, highHTF, lowHTF, closeHTF);

    // дальнейшая логика работы с timeHTF и ценами...

    return(rates_total);
}
```

Функция `saveInputs` принимает желаемый час начала дня (например `0` для 00:00) и период HTF в минутах. После инициализации необходимо вызвать `OnInitCalc`, затем при каждом вызове `OnCalculate` вызывать `Calc` и, при необходимости, `GetOHLC` для получения массивов цен более высокого таймфрейма.
