function memos = memologs(memos, memoboxH, spf)

    memos(1:end-1) = memos(2:end);
    memos{end} = spf;
    memoboxH.String = memos;
    pause(.02)

end