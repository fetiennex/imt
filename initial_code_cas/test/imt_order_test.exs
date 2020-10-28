defmodule ImtOrderTest do
  use ExUnit.Case

  @cases %{
    "4342"  => ["21","22"],
    "10"    => ["22","7"],  
    "7912"  => ["5","1"],
    "10000" => ["21","10"], 
    "1"     => ["9","22"]  
  }

  test "find with bisec" do
    for {id,stats}<-@cases do
      assert stats == ImtOrder.StatsAsDb.find_bisec("test/fixtures/stats.csv",id)
    end
  end

  test "find with enum same results" do
    for {id,_}<-@cases do
      assert ImtOrder.StatsAsDb.find_bisec("test/fixtures/stats.csv",id)
        == ImtOrder.StatsAsDb.find_enum("test/fixtures/stats.csv",id)
    end
  end

  test "compare timing" do
    IO.inspect :timer.tc(fn->
      Enum.each(1..100,fn _->
        ImtOrder.StatsAsDb.find_enum("test/fixtures/stats.csv","7912")
      end)
    end), label: "timing of enum search"
    IO.inspect :timer.tc(fn->
      Enum.each(1..100,fn _->
        ImtOrder.StatsAsDb.find_bisec("test/fixtures/stats.csv","7912")
      end)
    end), label: "timing of bisec search"
  end
end
