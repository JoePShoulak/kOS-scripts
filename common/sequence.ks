// sequences.ks

// TODO: Double check there's nothing else to review / improve here
// TODO: Rework this to not need a lexicon?

runOncePath("0:/util/core.ks").

declare global SEQ is lexicon(
  "IDLE", 0,
  "ACTIVE", 1,
  "COMPLETE", 2
).

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

function Mission {
  parameter sequence_func_list.

  declare sequence_list is list().
  declare all_steps is FlattenList(sequence_func_list).

  declare i is 1.
  for seq_func in all_steps {
    sequence_list:add(seq_func(i)).
    set i to i + 1.
  }

  for seq_i in sequence_list { seq_i["init"](). } wait 1. // Print sequence list
  for seq_i in sequence_list { seq_i["exec"](). } wait 3. // Execute sequence list
  
  for line in list(2, 3, 4, 5, 6, 7, 8, 9, 10) { ClearLine(line). } // TODO: Better clear (and move it)

  IdleScreen().
}
