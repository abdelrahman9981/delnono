import { strict as assert } from "node:assert";
import { nameKey } from "../../src/lib/nameKey";

describe("nameKey", () => {
  const same = (a: string, b: string) => assert.equal(nameKey(a), nameKey(b), `${a} vs ${b}`);

  it("trims and collapses whitespace", () => {
    same("  يوسف   أحمد ", "يوسف أحمد");
    same("يوسف\tأحمد", "يوسف أحمد");
  });

  it("ignores diacritics and tatweel", () => {
    same("يُوسُف", "يوسف");
    same("مـــريم", "مريم");
    same("محمّد", "محمد");
  });

  it("unifies alef forms, alef maqsura and ta marbuta", () => {
    same("أحمد", "احمد");
    same("إسراء", "اسراء");
    same("آدم", "ادم");
    same("هدى", "هدي");
    same("فاطمة", "فاطمه");
  });

  it("lowercases Latin", () => {
    same("Adam", "adam");
  });

  it("keeps different names different", () => {
    assert.notEqual(nameKey("يوسف"), nameKey("يونس"));
    assert.notEqual(nameKey("مريم"), nameKey("مريام"));
  });
});
