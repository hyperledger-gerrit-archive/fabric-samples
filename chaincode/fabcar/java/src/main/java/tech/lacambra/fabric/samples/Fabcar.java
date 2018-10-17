package tech.lacambra.fabric.samples;

import org.hyperledger.fabric.shim.ChaincodeBase;
import org.hyperledger.fabric.shim.ChaincodeStub;
import org.hyperledger.fabric.shim.ledger.KeyValue;
import org.hyperledger.fabric.shim.ledger.QueryResultsIterator;

import javax.json.Json;
import javax.json.JsonArray;
import javax.json.JsonObject;
import javax.json.stream.JsonCollectors;
import java.io.StringReader;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.logging.Logger;
import java.util.stream.StreamSupport;


public class Fabcar extends ChaincodeBase {

  private static final Logger LOGGER = Logger.getLogger(Fabcar.class.getName());

  public static void main(String[] args) {
    new Fabcar().start(args);
  }

  public Response init(ChaincodeStub chaincodeStub) {
    return newSuccessResponse();
  }

  public Response invoke(ChaincodeStub chaincodeStub) {

    Function function = Function.fromString(chaincodeStub.getFunction());
    Response response = null;

    LOGGER.info("[invoke] invoking function " + function.name());


    switch (function) {

      case queryCar:
        response = queryCar(chaincodeStub, chaincodeStub.getParameters());
        break;
      case initLedger:
        response = initLedger(chaincodeStub);
        break;
      case createCar:
        response = createCar(chaincodeStub, chaincodeStub.getParameters());
        break;
      case queryAllCars:
        response = queryAllCars(chaincodeStub);
        break;
      case changeCarOwner:
        response = changeCarOwner(chaincodeStub, chaincodeStub.getParameters());
        break;
      case none:
        response = newErrorResponse("Invalid Smart Contract function name: " + function.name());
        break;
    }

    LOGGER.info("[invoke] Sendinf response=" + response.getStatus());


    return response;
  }


  public Response queryCar(ChaincodeStub stub, List<String> args) {

    if (args.size() != 1) {
      return newErrorResponse("Incorrect number of arguments. Expecting 1");
    }

    byte[] carAsBytes = stub.getState(args.get(0));

    LOGGER.info(String.format("[queryCar] Get car %s = %s", args.get(0), new String(carAsBytes)));


    return newSuccessResponse(carAsBytes);
  }

  public Response initLedger(ChaincodeStub stub) {

    AtomicInteger i = new AtomicInteger(0);
    Arrays.asList(
        new Car("Toyota", "Prius", "blue", "Tomoko"),
        new Car("Ford", "Mustang", "red", "Brad"),
        new Car("Hyundai", "Tucson", "green", "Jin Soo"),
        new Car("Volkswagen", "Passat", "yellow", "Max"),
        new Car("Tesla", "S", "black", "Adriana"),
        new Car("Peugeot", "205", "purple", "Michel"),
        new Car("Chery", "S22L", "white", "Aarav"),
        new Car("Fiat", "Punto", "violet", "Pari"),
        new Car("Tata", "Nano", "indigo", "Valeria"),
        new Car("Holden", "Barina", "brown", "Shotaro")
    ).stream()
        .map(Car::toJson)
        .peek(c -> stub.putStringState(String.valueOf("CAR" + i.getAndIncrement()), c.toString()))
        .forEach(c -> LOGGER.info("[initLedger] Added car: " + c));

    return newSuccessResponse();
  }

  public Response createCar(ChaincodeStub stub, List<String> args) {

    if (args.size() != 5) {
      return newErrorResponse("Incorrect number of arguments. Expecting 5");
    }

    Car car = new Car(args.get(1), args.get(2), args.get(3), args.get(4));
    String carAsString = car.toJson().toString();
    stub.putStringState(args.get(0), carAsString);

    return newSuccessResponse();
  }

  public Response queryAllCars(ChaincodeStub stub) {

    String startKey = "CAR0";
    String endKey = "CAR999";

    try (QueryResultsIterator<KeyValue> it = stub.getStateByRange(startKey, endKey)) {

      JsonArray arr = StreamSupport.stream(it.spliterator(), false).map(this::toJsonRecord).collect(JsonCollectors.toJsonArray());
      LOGGER.info("[queryAllCars] CARS=" + arr);
      return newSuccessResponse(arr.toString().getBytes());

    } catch (Exception e) {
      return newErrorResponse(e);
    }
  }

  private JsonObject toJsonRecord(KeyValue kv) {

    JsonObject recordJson = Json.createReader(new StringReader(kv.getStringValue())).readObject();
    return Json.createObjectBuilder().add("Key", kv.getKey()).add("Record", recordJson).build();

  }

  public Response changeCarOwner(ChaincodeStub stub, List<String> args) {

    if (args.size() != 2) {
      return newErrorResponse("Incorrect number of arguments. Expecting 2");
    }

    Car car = Car.fromJson(stub.getStringState(args.get(0)));
    car.setOwner(args.get(1));

    stub.putStringState(args.get(0), car.toJson().toString());

    return newSuccessResponse();
  }

}
