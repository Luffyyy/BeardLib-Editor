function CoreEffectStack:move_down(idx)
	if idx == #self._stack then
		return idx
	end

	local e = self._stack[idx]

	table.remove(self._stack, idx)
    table.insert(self._stack, idx + 1, e)
    return idx + 1
end

function CoreEffectStack:move_up(idx)
	if idx == 1 then
		return idx
	end

	local e = self._stack[idx]

	table.remove(self._stack, idx)
    table.insert(self._stack, idx - 1, e)
    return idx - 1
end