/**
	In-memory streams

	Copyright: © 2012 RejectedSoftware e.K.
	License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
	Authors: Sönke Ludwig
*/
module vibe.stream.memory;

import vibe.core.stream;
import vibe.utils.array;
import vibe.utils.memory;

import std.algorithm;
import std.array;
import std.typecons;


/** OutputStream that collects the written data in memory and allows to query it
	as a byte array.
*/
class MemoryOutputStream : OutputStream {
	private {
		AllocAppender!(ubyte[]) m_destination;
	}

	this(Allocator alloc = defaultAllocator())
	{
		m_destination = AllocAppender!(ubyte[])(alloc);
	}

	/// Reserves space for data - useful for optimization.
	void reserve(size_t nbytes)
	{
		m_destination.reserve(nbytes);
	}

	/// An array with all data written to the stream so far.
	@property ubyte[] data() { return m_destination.data(); }

	void write(in ubyte[] bytes, bool do_flush = true)
	{
		m_destination.put(bytes);
	}

	void flush()
	{
	}

	void finalize()
	{
	}

	void write(InputStream stream, ulong nbytes = 0, bool do_flush = true)
	{
		writeDefault(stream, nbytes, do_flush);
	}
}


/**
	Provides a random access stream interface for accessing an array of bytes.
*/
class MemoryStream : RandomAccessStream {
	private {
		ubyte[] m_data;
		bool m_writable;
		size_t m_ptr = 0;
		size_t m_peekWindow;
	}

	/** Creates a new stream with the given data array as its contents.

		Params:
			data = The data array
			writable = Flag that controls whether the data array may be changed
	*/
	this(ubyte[] data, bool writable = true)
	{
		m_data = data;
		m_writable = writable;
		m_peekWindow = m_data.length;
	}

	/** Controls the maximum size of the array returned by peek().

		This property is mainly useful for debugging purposes.
	*/
	@property void peekWindow(size_t size) { m_peekWindow = size; }

	@property bool empty() { return leastSize() == 0; }
	@property ulong leastSize() { return m_data.length - m_ptr; }
	@property bool dataAvailableForRead() { return leastSize() > 0; }
	@property ulong size() const nothrow { return m_data.length; }
	@property bool readable() const nothrow { return true; }
	@property bool writable() const nothrow { return m_writable; }

	void seek(ulong offset) { assert(offset <= m_data.length); m_ptr = cast(size_t)offset; }
	ulong tell() nothrow { return m_ptr; }
	const(ubyte)[] peek() { return m_data[m_ptr .. min(m_data.length, m_ptr+m_peekWindow)]; }
	void read(ubyte[] dst) { assert(dst.length <= leastSize); dst[] = m_data[m_ptr .. m_ptr+dst.length]; m_ptr += dst.length; }
	void write(in ubyte[] bytes, bool do_flush = true) { assert(writable); assert(bytes.length <= leastSize); m_data[m_ptr .. m_ptr+bytes.length] = bytes; m_ptr += bytes.length; }
	void flush() {}
	void finalize() {}
	void write(InputStream stream, ulong nbytes = 0, bool do_flush = true) { writeDefault(stream, nbytes, do_flush); }
}
