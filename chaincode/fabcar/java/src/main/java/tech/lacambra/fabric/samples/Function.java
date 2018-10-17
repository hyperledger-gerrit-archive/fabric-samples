package tech.lacambra.fabric.samples;

import java.util.stream.Stream;

public enum Function {
  queryCar,
  initLedger,
  createCar,
  queryAllCars,
  changeCarOwner,
  none;

  public static Function fromString(String function) {

    return Stream.of(Function.values())
        .map(Enum::name)
        .filter(function::equals)
        .findAny().map(Function::valueOf)
        .orElse(none);

  }
}