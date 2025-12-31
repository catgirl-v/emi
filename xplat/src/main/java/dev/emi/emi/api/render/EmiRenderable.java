package dev.emi.emi.api.render;

import dev.emi.emi.runtime.EmiDrawContext;

/**
 * Provides a method to render something at a position
 */
public interface EmiRenderable {
	
	void render(EmiDrawContext context, int x, int y, float delta);
}
