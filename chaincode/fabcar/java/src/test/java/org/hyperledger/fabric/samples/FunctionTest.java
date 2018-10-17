package org.hyperledger.fabric.samples;

import org.junit.Test;
import tech.lacambra.fabric.samples.Function;

import static org.junit.Assert.*;

public class FunctionTest {


  @Test
  public void fromString() {

    assertEquals(Function.none, Function.fromString("something"));
    assertEquals(Function.queryCar, Function.fromString("queryCar"));
    assertEquals(Function.initLedger, Function.fromString("initLedger"));
    assertEquals(Function.createCar, Function.fromString("createCar"));
    assertEquals(Function.queryAllCars, Function.fromString("queryAllCars"));
    assertEquals(Function.changeCarOwner, Function.fromString("changeCarOwner"));

  }
}