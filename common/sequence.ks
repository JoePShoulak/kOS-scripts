// sequences.ks

runOncePath("0:/common/util.ks").

declare global SEQ is lexicon(
  "IDLE", 0,
  "ACTIVE", 1,
  "COMPLETE", 2
).

function FlattenList {
  parameter bulky_list.

  declare new_list is list().

  for li in bulky_list {
    if li:typename = "list" {
      until li:length = 0{
        new_list:add(li[0]).
        li:remove(0).
      }
    } else {
      new_list:add(li).
    }
  }

  return new_list.
}

function Sequence {
  parameter number.
  parameter text.
  parameter state is SEQ["ACTIVE"].

  local msg is "[" + (
    choose "X" if state = SEQ["COMPLETE"] else
    choose "-" if state = SEQ["ACTIVE"] else " "
  ) + "] " + number + ". " + text.
  print msg:padright(terminal:width) at(0, number + 1).
}

function ExecuteSequenceList {
  parameter sequence_func_list.

  declare sequence_list is list().

  declare all_steps is FlattenList(sequence_func_list).

  declare i is 1.
  for seq_func in all_steps {
    sequence_list:add(seq_func(i)).
    set i to i + 1.
  }

  for s in sequence_list { s["init"](). }
  wait 1.
  for s in sequence_list { s["exec"](). }
  wait 3.

  for line in list(2, 3, 4, 5, 6, 7, 8, 9, 10) {ClearLine(line).} // TODO: Better clear (and move it)

  IdleScreen().
}