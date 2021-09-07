module Transactions


export transaction, with_transaction, begin_transaction, commit_transaction, rollback_transaction


function begin_transaction end


function commit_transaction end


function rollback_transaction end


function transaction(f::Function)
  begin_transaction()

  try
    f()
  catch ex
    @error ex
    @info "Exception encountered during transaction, rolling back"

    rollback_transaction()
    rethrow(ex)
  end

  try
    commit_transaction()
  catch ex
    @error ex
    @info "Exception encountered when commiting transaction, rolling back"

    rollback_transaction()
    rethrow(ex)
  end
end
const with_transaction = transaction


end