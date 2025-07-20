# Работа с htf.mqh

`htf.mqh` содержит вспомогательные классы для построения баров более высокого таймфрейма (HTF) на основе имеющихся баров меньшего таймфрейма.

## Основные классы

### `CBarStorage`
Хранит данные одного бара: время открытия/закрытия, значения OHLC. Также предоставляет методы:
- `BarToString()` – текстовое представление бара.
- `GetPrice(ENUM_APPLIED_PRICE price)` – получить цену бара по типу (`PRICE_OPEN`, `PRICE_HIGH`, и т.д.).

### `CHTF`
Агрегатор, который собирает последовательность баров HTF. Основные методы:
- `SaveInputs(int dayStartHour, int periodMinutes)` – устанавливает начальный час дня и длительность одного HTF-бара в минутах.
- `OnInitCalc()` – очистка и первичная подготовка перед расчётом.
- `Calc(int rates_total, int prev_calculated)` – вызывается из `OnCalculate` индикатора для обновления агрегированных баров.
- `GetCurrentBarTimeOpen()` – время открытия текущего собираемого бара.

## Пример использования
```mq4
#include "htf.mqh"

CHTF htf;

int OnInit()
{
    // Строим часовые бары из минутных
    htf.SaveInputs(0, 60);
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

    // дальнейшая логика работы с данными HTF...

    return(rates_total);
}
```

Функция `SaveInputs` принимает желаемый час начала дня (например `0` для 00:00) и период HTF в минутах. После инициализации необходимо вызвать `OnInitCalc`, затем при каждом вызове `OnCalculate` вызывать `Calc` для обновления накопленных баров более высокого таймфрейма.
