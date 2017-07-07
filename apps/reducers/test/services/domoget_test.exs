defmodule ServiceDomoTest do
  use ExUnit.Case
  doctest Service.Domo

  test "splits csv string into chunks by store"do

    bin_audit_data_sample = "STORE,DATE,NO_OF_AUDITS_PERFORMED,PASSED_BIN_COUNT,BIN_COUNT_TOTAL,BIN_PERCENTAGE,_BATCH_ID_,_BATCH_LAST_RUN_,Store Name,Dimension,Territory,UPH Standard,District,store_id\n19,\\N,0,0,0,0.0,1,2017-01-18T22:21:04,Nike Company Store,Nike Store,Inline,NCS,NS01,19\n19,2017-01-23,1,19,20,95.0,2,2017-01-30T22:39:54,Nike Company Store,Nike Store,Inline,NCS,NS01,19\n51,\\N,0,0,0,0.0,1,2017-01-18T22:21:04,Airport,Nike Store,Inline,Nike  Store,NS01,51\n51,2017-02-21,2,36,38,94.7368421,5,2017-02-27T22:19:09,Airport,Nike Store,Inline,Nike Store,NS01,51\n51,2017-03-04,2,22,23,95.6521739,6,2017-03-08T17:15:47,Airport,Nike Store,Inline,Nike Store,NS01,51\n82,2017-06-17,1,18,20,90.0,18,2017-06-19T16:28:32,Seattle,Nike Store,Inline,Nike  Store,NS01,86\n86,2017-06-13,2,21,35,60.0,18,2017-06-19T16:28:32,San Francisco,Nike Store,Inline,Nike  Store,NS01,86\n237,2016-12-26,1,14,17,82.3529411,1,2017-01-18T22:21:04,Union Street,Nike Store,Inline,Nike Store,NS01,237\n237,2017-01-22,1,17,17,100.0,2,2017-01-30T22:39:54,Union Street,Nike Store,Inline,Nike Store,NS01,237\n305,\\N,0,0,0,0.0,6,2017-03-08T17:15:47,Stanford,Nike Store,Inline,Nike Store,NS01,305\n305,2017-04-21,2,17,22,77.2727272,11,2017-04-24T22:08:31,Stanford,Nike Store,Inline,Nike Store,NS01,305\n351,\\N,0,0,0,0.0,6,2017-03-08T17:15:47,University Village,Nike Store,Inline,Nike Store,NS01,351\n351,2017-03-09,1,12,18,66.6666666,7,2017-03-13T18:10:26,University Village,Nike Store,Inline,Nike Store,NS01,351\n351,2017-06-10,1,16,18,88.8888888,17,2017-06-13T19:30:13,University Village,Nike Store,Inline,Nike Store,NS01,351\n351,2017-06-17,1,14,18,77.7777777,18,2017-06-19T16:28:32,University Village,Nike Store,Inline,Nike Store,NS01,351\n360,\\N,0,0,0,0.0,1,2017-01-18T22:21:04,Eugene,Nike Store,Inline,Nike  Store,NS01,360\n360,2017-02-17,1,19,20,95.0,4,2017-02-21T18:21:43,Eugene,Nike Store,Inline,Nike Store,NS01,360\n360,2017-02-20,1,20,20,100.0,5,2017-02-27T22:19:09,Eugene,Nike Store,Inline,Nike Store,NS01,360\n368,2017-02-22,1,16,20,80.0,5,2017-02-27T22:19:09,Portland,Nike Store,Inline,Nike Store,NS01,368\n368,2017-02-23,1,16,20,80.0,5,2017-02-27T22:19:09,Portland,Nike Store,Inline,Nike Store,NS01,368\n93,2016-12-25,1,19,20,95.0,1,2017-01-18T22:21:04,Las Vegas,Nike Store,Inline,Nike Store,NS02,93\n93,2017-01-22,3,21,22,95.4545454,2,2017-01-30T22:39:54,Las Vegas,Nike Store,Inline,Nike Store,NS02,93\n246,2017-06-17,1,13,20,65.0,18,2017-06-19T16:28:32,The Grove,Nike Store,Inline,Nike Store,NS02,246\n246,2017-06-23,2,14,21,66.6666666,19,2017-06-26T18:05:05,The Grove,Nike Store,Inline,Nike Store,NS02,301\n301,2017-04-17,1,13,13,100.0,11,2017-04-24T22:08:31,Fashion Island,Nike Store,Inline,Nike Store,NS02,301\n301,2017-06-30,1,12,13,92.3076923,20,2017-07-05T21:07:49,Fashion Island,Nike Store,Inline,Nike Store,NS02,301\n303,\\N,0,0,0,0.0,1,2017-01-18T22:21:04,South Coast Plaza,Nike Store,Inline,Nike Store,NS02,303\n"

    actual = Service.Domo.chunk_by_store(bin_audit_data_sample, "STORE")
    expected = %{
      "19" => [
        %{"BIN_COUNT_TOTAL" => "0", "BIN_PERCENTAGE" => "0.0", "DATE" => "\\N", "Dimension" => "Nike Store", "District" => "NS01",
          "NO_OF_AUDITS_PERFORMED" => "0", "PASSED_BIN_COUNT" => "0", "STORE" => "19", "Store Name" => "Nike Company Store",
          "Territory" => "Inline", "UPH Standard" => "NCS", "_BATCH_ID_" => "1", "_BATCH_LAST_RUN_" => "2017-01-18T22:21:04", "store_id" => "19"},
        %{"BIN_COUNT_TOTAL" => "20", "BIN_PERCENTAGE" => "95.0", "DATE" => "2017-01-23", "Dimension" => "Nike Store", "District" => "NS01",
          "NO_OF_AUDITS_PERFORMED" => "1", "PASSED_BIN_COUNT" => "19", "STORE" => "19", "Store Name" => "Nike Company Store",
          "Territory" => "Inline", "UPH Standard" => "NCS", "_BATCH_ID_" => "2", "_BATCH_LAST_RUN_" => "2017-01-30T22:39:54", "store_id" => "19"}
      ],
      "237" => [
        %{"BIN_COUNT_TOTAL" => "17", "BIN_PERCENTAGE" => "82.3529411","DATE" => "2016-12-26", "Dimension" => "Nike Store", "District" => "NS01",
         "NO_OF_AUDITS_PERFORMED" => "1", "PASSED_BIN_COUNT" => "14", "STORE" => "237", "Store Name" => "Union Street",
         "Territory" => "Inline", "UPH Standard" => "Nike Store", "_BATCH_ID_" => "1", "_BATCH_LAST_RUN_" => "2017-01-18T22:21:04", "store_id" => "237"},
       %{"BIN_COUNT_TOTAL" => "17", "BIN_PERCENTAGE" => "100.0", "DATE" => "2017-01-22", "Dimension" => "Nike Store", "District" => "NS01",
         "NO_OF_AUDITS_PERFORMED" => "1", "PASSED_BIN_COUNT" => "17", "STORE" => "237", "Store Name" => "Union Street",
         "Territory" => "Inline", "UPH Standard" => "Nike Store", "_BATCH_ID_" => "2", "_BATCH_LAST_RUN_" => "2017-01-30T22:39:54", "store_id" => "237"}
      ],
      "246" => [
        %{"BIN_COUNT_TOTAL" => "20", "BIN_PERCENTAGE" => "65.0", "DATE" => "2017-06-17", "Dimension" => "Nike Store", "District" => "NS02",
          "NO_OF_AUDITS_PERFORMED" => "1", "PASSED_BIN_COUNT" => "13", "STORE" => "246", "Store Name" => "The Grove",
          "Territory" => "Inline", "UPH Standard" => "Nike Store", "_BATCH_ID_" => "18", "_BATCH_LAST_RUN_" => "2017-06-19T16:28:32", "store_id" => "246"},
       %{"BIN_COUNT_TOTAL" => "21", "BIN_PERCENTAGE" => "66.6666666", "DATE" => "2017-06-23", "Dimension" => "Nike Store", "District" => "NS02",
        "NO_OF_AUDITS_PERFORMED" => "2", "PASSED_BIN_COUNT" => "14", "STORE" => "246", "Store Name" => "The Grove",
        "Territory" => "Inline", "UPH Standard" => "Nike Store", "_BATCH_ID_" => "19", "_BATCH_LAST_RUN_" => "2017-06-26T18:05:05", "store_id" => "301"}
      ],
      "301" => [
        %{"BIN_COUNT_TOTAL" => "13", "BIN_PERCENTAGE" => "100.0","DATE" => "2017-04-17", "Dimension" => "Nike Store", "District" => "NS02",
          "NO_OF_AUDITS_PERFORMED" => "1", "PASSED_BIN_COUNT" => "13", "STORE" => "301", "Store Name" => "Fashion Island",
          "Territory" => "Inline", "UPH Standard" => "Nike Store", "_BATCH_ID_" => "11", "_BATCH_LAST_RUN_" => "2017-04-24T22:08:31", "store_id" => "301"},
       %{"BIN_COUNT_TOTAL" => "13", "BIN_PERCENTAGE" => "92.3076923", "DATE" => "2017-06-30", "Dimension" => "Nike Store", "District" => "NS02",
         "NO_OF_AUDITS_PERFORMED" => "1", "PASSED_BIN_COUNT" => "12", "STORE" => "301", "Store Name" => "Fashion Island",
         "Territory" => "Inline", "UPH Standard" => "Nike Store", "_BATCH_ID_" => "20", "_BATCH_LAST_RUN_" => "2017-07-05T21:07:49", "store_id" => "301"}
      ],
      "303" => [
        %{"BIN_COUNT_TOTAL" => "0", "BIN_PERCENTAGE" => "0.0", "DATE" => "\\N", "Dimension" => "Nike Store", "District" => "NS02",
        "NO_OF_AUDITS_PERFORMED" => "0", "PASSED_BIN_COUNT" => "0", "STORE" => "303", "Store Name" => "South Coast Plaza",
        "Territory" => "Inline", "UPH Standard" => "Nike Store", "_BATCH_ID_" => "1", "_BATCH_LAST_RUN_" => "2017-01-18T22:21:04", "store_id" => "303"}
      ],
      "305" => [
        %{"BIN_COUNT_TOTAL" => "0", "BIN_PERCENTAGE" => "0.0", "DATE" => "\\N", "Dimension" => "Nike Store", "District" => "NS01",
          "NO_OF_AUDITS_PERFORMED" => "0", "PASSED_BIN_COUNT" => "0", "STORE" => "305", "Store Name" => "Stanford",
          "Territory" => "Inline", "UPH Standard" => "Nike Store", "_BATCH_ID_" => "6", "_BATCH_LAST_RUN_" => "2017-03-08T17:15:47", "store_id" => "305"},
        %{"BIN_COUNT_TOTAL" => "22", "BIN_PERCENTAGE" => "77.2727272", "DATE" => "2017-04-21", "Dimension" => "Nike Store", "District" => "NS01",
          "NO_OF_AUDITS_PERFORMED" => "2", "PASSED_BIN_COUNT" => "17", "STORE" => "305", "Store Name" => "Stanford",
          "Territory" => "Inline", "UPH Standard" => "Nike Store", "_BATCH_ID_" => "11", "_BATCH_LAST_RUN_" => "2017-04-24T22:08:31", "store_id" => "305"}
      ],
      "351" => [
        %{"BIN_COUNT_TOTAL" => "0", "BIN_PERCENTAGE" => "0.0", "DATE" => "\\N", "Dimension" => "Nike Store", "District" => "NS01",
          "NO_OF_AUDITS_PERFORMED" => "0", "PASSED_BIN_COUNT" => "0", "STORE" => "351", "Store Name" => "University Village",
          "Territory" => "Inline", "UPH Standard" => "Nike Store", "_BATCH_ID_" => "6", "_BATCH_LAST_RUN_" => "2017-03-08T17:15:47", "store_id" => "351"},
        %{"BIN_COUNT_TOTAL" => "18", "BIN_PERCENTAGE" => "66.6666666", "DATE" => "2017-03-09", "Dimension" => "Nike Store", "District" => "NS01",
          "NO_OF_AUDITS_PERFORMED" => "1", "PASSED_BIN_COUNT" => "12", "STORE" => "351", "Store Name" => "University Village",
          "Territory" => "Inline", "UPH Standard" => "Nike Store", "_BATCH_ID_" => "7", "_BATCH_LAST_RUN_" => "2017-03-13T18:10:26", "store_id" => "351"},
        %{"BIN_COUNT_TOTAL" => "18", "BIN_PERCENTAGE" => "88.8888888", "DATE" => "2017-06-10", "Dimension" => "Nike Store", "District" => "NS01",
          "NO_OF_AUDITS_PERFORMED" => "1", "PASSED_BIN_COUNT" => "16", "STORE" => "351", "Store Name" => "University Village",
          "Territory" => "Inline", "UPH Standard" => "Nike Store", "_BATCH_ID_" => "17", "_BATCH_LAST_RUN_" => "2017-06-13T19:30:13", "store_id" => "351"},
        %{"BIN_COUNT_TOTAL" => "18", "BIN_PERCENTAGE" => "77.7777777", "DATE" => "2017-06-17", "Dimension" => "Nike Store", "District" => "NS01",
          "NO_OF_AUDITS_PERFORMED" => "1", "PASSED_BIN_COUNT" => "14", "STORE" => "351", "Store Name" => "University Village",
          "Territory" => "Inline", "UPH Standard" => "Nike Store", "_BATCH_ID_" => "18", "_BATCH_LAST_RUN_" => "2017-06-19T16:28:32", "store_id" => "351"}
      ],
      "360" => [
        %{"BIN_COUNT_TOTAL" => "0", "BIN_PERCENTAGE" => "0.0", "DATE" => "\\N", "Dimension" => "Nike Store", "District" => "NS01",
          "NO_OF_AUDITS_PERFORMED" => "0", "PASSED_BIN_COUNT" => "0", "STORE" => "360", "Store Name" => "Eugene",
          "Territory" => "Inline", "UPH Standard" => "Nike  Store", "_BATCH_ID_" => "1", "_BATCH_LAST_RUN_" => "2017-01-18T22:21:04", "store_id" => "360"},
        %{"BIN_COUNT_TOTAL" => "20", "BIN_PERCENTAGE" => "95.0", "DATE" => "2017-02-17", "Dimension" => "Nike Store", "District" => "NS01",
          "NO_OF_AUDITS_PERFORMED" => "1", "PASSED_BIN_COUNT" => "19", "STORE" => "360", "Store Name" => "Eugene",
          "Territory" => "Inline", "UPH Standard" => "Nike Store", "_BATCH_ID_" => "4", "_BATCH_LAST_RUN_" => "2017-02-21T18:21:43", "store_id" => "360"},
        %{"BIN_COUNT_TOTAL" => "20", "BIN_PERCENTAGE" => "100.0", "DATE" => "2017-02-20", "Dimension" => "Nike Store", "District" => "NS01",
          "NO_OF_AUDITS_PERFORMED" => "1", "PASSED_BIN_COUNT" => "20", "STORE" => "360", "Store Name" => "Eugene",
          "Territory" => "Inline", "UPH Standard" => "Nike Store", "_BATCH_ID_" => "5", "_BATCH_LAST_RUN_" => "2017-02-27T22:19:09", "store_id" => "360"}
      ],
      "368" => [
        %{"BIN_COUNT_TOTAL" => "20", "BIN_PERCENTAGE" => "80.0", "DATE" => "2017-02-22", "Dimension" => "Nike Store", "District" => "NS01",
          "NO_OF_AUDITS_PERFORMED" => "1", "PASSED_BIN_COUNT" => "16", "STORE" => "368", "Store Name" => "Portland",
          "Territory" => "Inline", "UPH Standard" => "Nike Store", "_BATCH_ID_" => "5", "_BATCH_LAST_RUN_" => "2017-02-27T22:19:09", "store_id" => "368"},
        %{"BIN_COUNT_TOTAL" => "20", "BIN_PERCENTAGE" => "80.0", "DATE" => "2017-02-23", "Dimension" => "Nike Store", "District" => "NS01",
          "NO_OF_AUDITS_PERFORMED" => "1", "PASSED_BIN_COUNT" => "16", "STORE" => "368", "Store Name" => "Portland",
          "Territory" => "Inline", "UPH Standard" => "Nike Store", "_BATCH_ID_" => "5", "_BATCH_LAST_RUN_" => "2017-02-27T22:19:09", "store_id" => "368"}
      ],
      "51" => [
        %{"BIN_COUNT_TOTAL" => "0", "BIN_PERCENTAGE" => "0.0", "DATE" => "\\N", "Dimension" => "Nike Store", "District" => "NS01",
          "NO_OF_AUDITS_PERFORMED" => "0", "PASSED_BIN_COUNT" => "0", "STORE" => "51", "Store Name" => "Airport",
          "Territory" => "Inline", "UPH Standard" => "Nike  Store", "_BATCH_ID_" => "1", "_BATCH_LAST_RUN_" => "2017-01-18T22:21:04", "store_id" => "51"},
        %{"BIN_COUNT_TOTAL" => "38", "BIN_PERCENTAGE" => "94.7368421", "DATE" => "2017-02-21", "Dimension" => "Nike Store", "District" => "NS01",
          "NO_OF_AUDITS_PERFORMED" => "2", "PASSED_BIN_COUNT" => "36", "STORE" => "51", "Store Name" => "Airport",
          "Territory" => "Inline", "UPH Standard" => "Nike Store", "_BATCH_ID_" => "5", "_BATCH_LAST_RUN_" => "2017-02-27T22:19:09", "store_id" => "51"},
        %{"BIN_COUNT_TOTAL" => "23", "BIN_PERCENTAGE" => "95.6521739", "DATE" => "2017-03-04", "Dimension" => "Nike Store", "District" => "NS01",
          "NO_OF_AUDITS_PERFORMED" => "2", "PASSED_BIN_COUNT" => "22", "STORE" => "51", "Store Name" => "Airport",
          "Territory" => "Inline", "UPH Standard" => "Nike Store", "_BATCH_ID_" => "6", "_BATCH_LAST_RUN_" => "2017-03-08T17:15:47", "store_id" => "51"}
      ],
      "82" => [
        %{"BIN_COUNT_TOTAL" => "20", "BIN_PERCENTAGE" => "90.0", "DATE" => "2017-06-17", "Dimension" => "Nike Store", "District" => "NS01",
          "NO_OF_AUDITS_PERFORMED" => "1", "PASSED_BIN_COUNT" => "18", "STORE" => "82", "Store Name" => "Seattle",
          "Territory" => "Inline", "UPH Standard" => "Nike  Store", "_BATCH_ID_" => "18", "_BATCH_LAST_RUN_" => "2017-06-19T16:28:32", "store_id" => "86"}
      ],
      "86" => [
        %{"BIN_COUNT_TOTAL" => "35", "BIN_PERCENTAGE" => "60.0", "DATE" => "2017-06-13", "Dimension" => "Nike Store", "District" => "NS01",
          "NO_OF_AUDITS_PERFORMED" => "2", "PASSED_BIN_COUNT" => "21", "STORE" => "86", "Store Name" => "San Francisco",
          "Territory" => "Inline", "UPH Standard" => "Nike  Store", "_BATCH_ID_" => "18", "_BATCH_LAST_RUN_" => "2017-06-19T16:28:32", "store_id" => "86"}
      ],
      "93" => [
        %{"BIN_COUNT_TOTAL" => "20", "BIN_PERCENTAGE" => "95.0", "DATE" => "2016-12-25", "Dimension" => "Nike Store", "District" => "NS02",
          "NO_OF_AUDITS_PERFORMED" => "1", "PASSED_BIN_COUNT" => "19", "STORE" => "93", "Store Name" => "Las Vegas",
          "Territory" => "Inline", "UPH Standard" => "Nike Store", "_BATCH_ID_" => "1", "_BATCH_LAST_RUN_" => "2017-01-18T22:21:04", "store_id" => "93"},
        %{"BIN_COUNT_TOTAL" => "22", "BIN_PERCENTAGE" => "95.4545454", "DATE" => "2017-01-22", "Dimension" => "Nike Store", "District" => "NS02",
          "NO_OF_AUDITS_PERFORMED" => "3", "PASSED_BIN_COUNT" => "21", "STORE" => "93", "Store Name" => "Las Vegas",
          "Territory" => "Inline", "UPH Standard" => "Nike Store", "_BATCH_ID_" => "2", "_BATCH_LAST_RUN_" => "2017-01-30T22:39:54", "store_id" => "93"}
      ]
    }

    assert(actual == expected)
end

end
